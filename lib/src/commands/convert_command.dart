// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class ConvertCommand extends Command<int> {
  ConvertCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'to',
        abbr: 't',
        allowed: <String>['graphql', 'rest'],
        help: 'Target API type (graphql or rest).',
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Show which files would be changed without applying them.',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get name => 'convert';

  @override
  String get description => 'Convert a feature module between GraphQL and REST data layers.';

  @override
  Future<int> run() async {
    final String? projectRoot = findProjectRoot();
    if (projectRoot == null) {
      _logger.err('Could not find a Flutter project root.');
      return 1;
    }

    final SimplexConfig? config = loadConfig(projectRoot);
    if (config == null) {
      _logger.err("No simplex.yaml found. Run 'simplex init' first.");
      return 1;
    }

    // Explicit CLI flag wins; otherwise defer to simplex.yaml (set by `simplex init`).
    final bool isInteractive = argResults?.wasParsed('interactive') == true
        ? (argResults!['interactive'] as bool)
        : config.interactive;

    // ── Resolve feature name ─────────────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults!.rest.isNotEmpty ? argResults!.rest.first : null,
      interactive: isInteractive,
    );

    if (!config.features.containsKey(featureName)) {
      _logger.err("Feature '$featureName' is not registered in simplex.yaml.");
      return 1;
    }

    final FeatureConfig featureConfig = config.features[featureName]!;

    // ── Resolve target API ───────────────────────────────────────────────────
    final String targetApi = (isInteractive
            ? Select(
                prompt: 'Convert ${featureName} to:',
                options: <String>['graphql', 'rest'],
              ).interact().let((int i) => i == 0 ? 'graphql' : 'rest')
            : (featureConfig.api == 'graphql' ? 'rest' : 'graphql'));

    if (targetApi == featureConfig.api) {
      _logger.info('Feature ${featureName} is already using ${targetApi}. No changes needed.');
      return 0;
    }

    final bool dryRun = argResults?['dry-run'] as bool? ?? false;

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — convert')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  From    : ${yellow.wrap(featureConfig.api)}');
    _logger.info('  To      : ${green.wrap(targetApi)}');
    if (dryRun) _logger.info('  Mode    : ${magenta.wrap("DRY RUN")}');
    _logger.info('');

    final Progress progress =
        _logger.progress(dryRun ? 'Analyzing changes...' : 'Converting data layer...');

    try {
      await FeatureGenerator.convertDataLayer(
        projectRoot: projectRoot,
        config: config,
        featureName: featureName,
        featureClass: toUpperCamelCase(featureName),
        targetApi: targetApi,
        usePaging: featureConfig.paging,
        dryRun: dryRun,
        logger: _logger,
      );

      if (!dryRun) {
        // Update simplex.yaml
        final SimplexConfig newConfig = config.copyWith(
          features: <String, FeatureConfig>{
            ...config.features,
            featureName: featureConfig.copyWith(api: targetApi),
          },
        );
        saveConfig(projectRoot, newConfig);
        progress.complete('Converted ${featureName} to ${targetApi}!');
      } else {
        progress.complete('Analysis complete (dry run).');
      }
    } catch (e) {
      progress.fail('Conversion failed: $e');
      return 1;
    }

    return 0;
  }
}

extension CopyFeature on FeatureConfig {
  FeatureConfig copyWith({String? api, bool? paging}) => FeatureConfig(
        api: api ?? this.api,
        paging: paging ?? this.paging,
      );
}

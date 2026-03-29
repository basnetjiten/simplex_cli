// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class AddPagingCommand extends Command<int> {
  AddPagingCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'paging';

  @override
  String get description => 'Add paging support (PagingCubit) to an existing feature.';

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
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    if (!config.features.containsKey(featureName)) {
      _logger.err("Feature '$featureName' is not registered in simplex.yaml.");
      return 1;
    }

    final FeatureConfig featureConfig = config.features[featureName]!;
    if (featureConfig.paging) {
      _logger.info('Feature $featureName already has paging enabled.');
      return 0;
    }

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — add paging')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('');

    final Progress progress = _logger.progress('Adding paging support...');

    try {
      // Re-run the feature generator with use_paging: true.
      // Mason will prompt for conflicts or we can overwrite if confident.
      await FeatureGenerator.generate(
        projectRoot: projectRoot,
        config: config,
        featureName: featureName,
        featureClass: toUpperCamelCase(featureName),
        apiType: featureConfig.api,
        usePaging: true,
        generateTests: false, // Don't re-generate tests by default
      );

      // Update simplex.yaml
      final SimplexConfig newConfig = config.copyWith(
        features: <String, FeatureConfig>{
          ...config.features,
          featureName: FeatureConfig(api: featureConfig.api, paging: true),
        },
      );
      saveConfig(projectRoot, newConfig);

      progress.complete('Paging support added to $featureName!');
    } catch (e) {
      progress.fail('Failed to add paging: $e');
      return 1;
    }

    return 0;
  }
}

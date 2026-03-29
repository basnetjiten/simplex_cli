// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';

class MakeFeatureCommand extends Command<int> {
  MakeFeatureCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'api',
        abbr: 'a',
        help: 'API type (graphql or rest). Uses default_api from simplex.yaml if omitted.',
      )
      ..addFlag(
        'paging',
        abbr: 'p',
        help: 'Enable paging for the feature.',
        defaultsTo: null,
      )
      ..addFlag(
        'tests',
        abbr: 't',
        help: 'Generate tests for the feature.',
        defaultsTo: null,
      );
  }

  final Logger _logger;

  @override
  String get name => 'make:feature';

  @override
  String get description => 'Scaffold a new feature module using Simplex Clean Architecture.';

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

    // ── Resolve name (positional) ────────────────────────────────────────────
    String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first;
    } else if (isInteractive) {
      rawName = Input(prompt: 'Feature name (snake_case, e.g. user_profile)').interact();
    } else {
      throw UsageException(
        'Feature name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String featureName = snakeCase(rawName);
    final String featureClass = toUpperCamelCase(featureName);

    if (config.features.containsKey(featureName) && !isInteractive) {
      _logger.err("Feature '$featureName' already exists. Cannot overwrite in non-interactive mode.");
      return 1;
    }

    if (config.features.containsKey(featureName)) {
      final bool force = Confirm(
        prompt: "Feature '$featureName' already exists. Overwrite?",
        defaultValue: false,
      ).interact();
      if (!force) return 0;
    }

    // ── Resolve API type ─────────────────────────────────────────────────────
    final String apiType = argResults?['api'] as String? ?? config.defaultApi;

    // ── Resolve flags ───────────────────────────────────────────────────────
    final bool usePaging = argResults?.wasParsed('paging') == true
        ? argResults!['paging'] as bool
        : (isInteractive ? Confirm(prompt: 'Enable pagination (PagingCubit)?', defaultValue: false).interact() : false);

    final bool generateTests = argResults?.wasParsed('tests') == true
        ? argResults!['tests'] as bool
        : (isInteractive ? Confirm(prompt: 'Generate unit tests?', defaultValue: true).interact() : true);

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:feature')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Class   : ${cyan.wrap(featureClass)}');
    _logger.info('  API     : ${cyan.wrap(apiType)}');
    _logger.info('  Paging  : ${cyan.wrap(usePaging.toString())}');
    _logger.info('  Tests   : ${cyan.wrap(generateTests.toString())}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating feature $featureName...');
    try {
      await FeatureGenerator.generate(
        projectRoot: projectRoot,
        config: config,
        featureName: featureName,
        featureClass: featureClass,
        apiType: apiType,
        usePaging: usePaging,
        generateTests: generateTests,
      );

      // Register the new feature in simplex.yaml
      final FeatureConfig featureConfig = FeatureConfig(
        api: apiType,
        paging: usePaging,
      );
      final SimplexConfig newConfig = config.copyWith(
        features: <String, FeatureConfig>{
          ...config.features,
          featureName: featureConfig,
        },
      );
      saveConfig(projectRoot, newConfig);

      progress.complete('Feature $featureName generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    _logger.info('');
    _logger.success('✅  Done! Next steps:');
    _logger.info('  Run dart run build_runner build --delete-conflicting-outputs');
    _logger.info('');

    return 0;
  }
}

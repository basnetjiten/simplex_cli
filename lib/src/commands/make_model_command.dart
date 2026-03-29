import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeModelCommand extends Command<int> {
  MakeModelCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'api',
      abbr: 'a',
      help: 'Implementation type (graphql/rest). Defaults to simplex.yaml default.',
      allowed: <String>['graphql', 'rest'],
    );
  }

  final Logger _logger;

  @override
  String get name => 'make:model';

  @override
  String get description =>
      'Create a new freezed Data Model inside a feature\'s data/models/ folder.\n'
      'Example: simplex make:model User\n'
      '         simplex make:model UserProfile --api rest\n'
      'Path-aware: run from inside a feature folder to skip the feature prompt.';

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

    // ── Resolve name (positional) ────────────────────────────────────────────
    final String rawName = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : Input(prompt: 'Model name (PascalCase, e.g. User)').interact();

    final String modelClass = toUpperCamelCase(snakeCase(rawName));
    final String modelSnake = snakeCase(rawName);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
    );

    final String apiType = argResults?['api'] as String? ?? config.defaultApi;

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:model')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Model   : ${cyan.wrap('${modelClass}Model')}');
    _logger.info('  API     : ${cyan.wrap(apiType)}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Data Model...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'model',
        featureName: featureName,
        featureClass: '',
        additionalVars: <String, dynamic>{
          'model_name': modelSnake,
          'model_class': modelClass,
          'use_graphql': apiType == 'graphql',
        },
      );
      progress.complete('${modelClass}Model generated!');
      await FeatureGenerator.runBuildRunner(projectRoot, _logger);
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

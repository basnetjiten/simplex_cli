import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeDomainCommand extends Command<int> {
  MakeDomainCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'make:domain';

  @override
  String get description =>
      'Create a domain entity (freezed) + a use-case stub for a feature.\n'
      'Example: simplex make:domain User\n'
      'Path-aware: run from inside a feature folder to skip the feature prompt.\n'
      'Requires an existing feature. Run \'simplex make:feature\' first if none exist.';

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

    // ── Guard: must have at least one registered feature ─────────────────────
    if (config.features.isEmpty) {
      _logger.err(
        'No features registered in simplex.yaml.\n'
        "Run 'simplex make:feature <Name>' first to scaffold a feature, "
        'then add domain objects to it.',
      );
      return 1;
    }

    // ── Resolve name (positional) ────────────────────────────────────────────
    final String rawName = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : Input(prompt: 'Entity name (PascalCase, e.g. User)').interact();

    final String entityClass = toUpperCamelCase(snakeCase(rawName));
    final String entitySnake = snakeCase(rawName);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
    );

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:domain')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Entity  : ${cyan.wrap(entityClass)}');
    _logger.info('  Creates :');
    _logger.info(
      '    ${darkGray.wrap('domain/entities/')}${cyan.wrap('$entitySnake.dart')}  (freezed entity)',
    );
    _logger.info(
      '    ${darkGray.wrap('domain/usecases/')}${cyan.wrap('get_${entitySnake}_usecase.dart')}  (use-case stub)',
    );
    _logger.info('');

    final Progress progress = _logger.progress('Generating Domain objects...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'domain',
        featureName: featureName,
        featureClass: entityClass,
        additionalVars: <String, dynamic>{
          'entity_name': entitySnake,
          'entity_class': entityClass,
        },
      );
      progress.complete('$entityClass entity + use-case generated!');
      await FeatureGenerator.runBuildRunner(projectRoot, _logger);
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeRepositoryCommand extends Command<int> {
  MakeRepositoryCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'api',
      abbr: 'a',
      help: 'API type for the implementation stub (graphql/rest).',
      allowed: <String>['graphql', 'rest'],
    );
  }

  final Logger _logger;

  @override
  String get name => 'make:repository';

  @override
  String get description =>
      'Create a repository abstract interface (domain/) + concrete implementation (data/).\n'
      'Example: simplex make:repository User\n'
      '         simplex make:repository Order --api rest\n'
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
        'then add a repository to it.',
      );
      return 1;
    }

    // ── Resolve name (positional) ────────────────────────────────────────────
    final String rawName = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : Input(prompt: 'Repository name (PascalCase, e.g. User)').interact();

    final String repoClass = toUpperCamelCase(snakeCase(rawName));
    final String repoSnake = snakeCase(rawName);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
    );

    final String apiType = argResults?['api'] as String? ?? config.defaultApi;

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:repository')!);
    _logger.info('  Feature    : ${cyan.wrap(featureName)}');
    _logger.info('  Repository : ${cyan.wrap('${repoClass}Repository')}');
    _logger.info('  API        : ${cyan.wrap(apiType)}');
    _logger.info('  Creates    :');
    _logger.info(
      '    ${darkGray.wrap('domain/repositories/')}${cyan.wrap('${repoSnake}_repository.dart')}  (interface)',
    );
    _logger.info(
      '    ${darkGray.wrap('data/repositories/')}${cyan.wrap('${repoSnake}_repository_impl.dart')}  (impl)',
    );
    _logger.info('');

    final Progress progress = _logger.progress('Generating Repository...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'repository',
        featureName: featureName,
        featureClass: repoClass,
        additionalVars: <String, dynamic>{
          'repo_name': repoSnake,
          'repo_class': repoClass,
          'use_graphql': apiType == 'graphql',
        },
      );
      progress.complete('${repoClass}Repository generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

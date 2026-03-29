// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeRepoCommand extends Command<int> {
  MakeRepoCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
      )
      ..addFlag(
        'abstract-only',
        abbr: 'a',
        help: 'Generate only the repository interface (domain/).',
        negatable: false,
      )
      ..addFlag(
        'impl-only',
        abbr: 'i',
        help: 'Generate only the repository implementation (data/).',
        negatable: false,
      )
      ..addOption(
        'api',
        help: 'API type for the implementation stub (graphql/rest).',
        allowed: <String>['graphql', 'rest'],
      );
  }

  final Logger _logger;

  @override
  String get name => 'make:repo';

  @override
  String get description => 'Create a repository interface (domain/) and/or concrete implementation (data/).\n'
      'Example: simplex make:repo user_profile\n'
      '         simplex make:repo user_profile -a (interface only)\n'
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

    // ── Guard: must have at least one registered feature ─────────────────────
    if (config.features.isEmpty) {
      _logger.err(
        'No features registered in simplex.yaml.\n'
        "Run 'simplex make:feature <Name>' first to scaffold a feature, "
        'then add a repository to it.',
      );
      return 1;
    }

    final bool isInteractive = (argResults?['interactive'] as bool?) ??
        (globalResults?['interactive'] as bool?) ??
        true;

    // ── Resolve name (positional) ────────────────────────────────────────────
    bool isSnakeCase(String v) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v.trim());

    String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first.trim();
      if (!isSnakeCase(rawName)) {
        _logger.err(
          "'$rawName' is not snake_case. "
          'Please use snake_case for the repository name (e.g. user_profile).',
        );
        return 1;
      }
    } else if (isInteractive) {
      rawName = Input(
        prompt: 'Repository name (snake_case, e.g. user_profile)',
        validator: (String val) {
          if (val.trim().isEmpty) return false;
          if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val.trim())) return false;
          return true;
        },
      ).interact().trim();
    } else {
      throw UsageException(
        'Repository name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String repoClass = toUpperCamelCase(rawName);
    final String repoSnake = rawName;

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    final String apiType = argResults?['api'] as String? ?? config.defaultApi;

    // ── Resolve generation flags ─────────────────────────────────────────────
    final bool abstractOnly = argResults!['abstract-only'] as bool;
    final bool implOnly = argResults!['impl-only'] as bool;

    bool createAbstract = true;
    bool createImpl = true;

    if (abstractOnly) {
      createAbstract = true;
      createImpl = false;
    } else if (implOnly) {
      createAbstract = false;
      createImpl = true;
    }

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:repo')!);
    _logger.info('  Feature    : ${cyan.wrap(featureName)}');
    _logger.info('  Repository : ${cyan.wrap('${repoClass}Repository')}');
    _logger.info('  API        : ${cyan.wrap(apiType)}');
    _logger.info(
        '  Scope      : ${createAbstract && createImpl ? "Both" : (createAbstract ? "Abstract Only" : "Implementation Only")}');
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
          'create_abstract': createAbstract,
          'create_impl': createImpl,
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

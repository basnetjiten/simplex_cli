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
        help: 'Only generate the abstract interface in domain.',
        negatable: false,
      )
      ..addFlag(
        'impl-only',
        help: 'Only generate the implementation in data.',
        negatable: false,
      )
      ..addFlag(
        'source',
        abbr: 's',
        help: 'Generate a remote data source alongside the repository.',
        defaultsTo: true,
      )
      ..addFlag(
        'model',
        abbr: 'm',
        help: 'Generate a data model alongside the repository.',
        defaultsTo: true,
      );
  }

  final Logger _logger;

  @override
  String get name => 'make:repo';

  @override
  String get description => 'Create a repository (abstract + impl) with its source and model.\n'
      'Example: simplex make:repo auth\n'
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

    // Explicit CLI flag wins; otherwise defer to simplex.yaml (set by `simplex init`).
    final bool isInteractive = argResults?.wasParsed('interactive') == true
        ? (argResults!['interactive'] as bool)
        : config.interactive;

    // ── Resolve name (positional) ────────────────────────────────────────────
    String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first;
    } else if (isInteractive) {
      rawName = Input(prompt: 'Component name (snake_case, e.g. auth)').interact();
    } else {
      throw UsageException(
        'Component name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String baseSnake = snakeCase(rawName);
    final String baseClass = toUpperCamelCase(baseSnake);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    final bool abstractOnly = argResults?['abstract-only'] as bool? ?? false;
    final bool implOnly = argResults?['impl-only'] as bool? ?? false;
    final bool createSource = argResults?['source'] as bool? ?? true;
    final bool createModel = argResults?['model'] as bool? ?? true;

    if (abstractOnly && implOnly) {
      _logger.err('Cannot use both --abstract-only and --impl-only.');
      return 1;
    }

    final bool createAbstract = !implOnly;
    final bool createImpl = !abstractOnly;
    final bool useGraphql = config.features[featureName]?.api == 'graphql' || (config.features[featureName] == null && config.defaultApi == 'graphql');

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:repo (with data stack)')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Base    : ${cyan.wrap(baseClass)}');
    _logger.info('  Repo    : ${cyan.wrap('${createAbstract ? "Abstract" : ""} ${createImpl ? "Implementation" : ""}'.trim())}');
    _logger.info('  Source  : ${cyan.wrap(createSource.toString())}');
    _logger.info('  Model   : ${cyan.wrap(createModel.toString())}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Repository components...');
    try {
      // 1. Generate Repository
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'repository',
        featureName: featureName,
        featureClass: baseClass,
        additionalVars: <String, dynamic>{
          'repo_name': baseSnake,
          'repo_class': baseClass,
          'use_graphql': useGraphql,
          'create_abstract': createAbstract,
          'create_impl': createImpl,
        },
      );

      // 2. Generate Source (if requested)
      if (createSource && !abstractOnly) {
        await FeatureGenerator.generateComponent(
          projectRoot: projectRoot,
          config: config,
          brickName: 'source',
          featureName: featureName,
          featureClass: baseClass,
          additionalVars: <String, dynamic>{
            'source_name': baseSnake,
            'source_class': baseClass,
            'use_graphql': useGraphql,
            'create_abstract': createAbstract,
            'create_impl': createImpl,
          },
        );
      }

      // 3. Generate Model (if requested)
      if (createModel && !abstractOnly) {
        await FeatureGenerator.generateComponent(
          projectRoot: projectRoot,
          config: config,
          brickName: 'model',
          featureName: featureName,
          featureClass: baseClass,
          additionalVars: <String, dynamic>{
            'model_name': baseSnake,
            'model_class': baseClass,
            'use_graphql': useGraphql,
          },
        );
      }

      progress.complete('$baseClass Repository components generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

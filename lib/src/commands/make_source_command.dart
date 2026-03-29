// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeSourceCommand extends Command<int> {
  MakeSourceCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
      )
      ..addFlag(
        'abstract-only',
        abbr: 'a',
        help: 'Generate only the remote source interface (domain/).',
        negatable: false,
      )
      ..addFlag(
        'impl-only',
        abbr: 'i',
        help: 'Generate only the remote source implementation (data/).',
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
  String get name => 'make:source';

  @override
  String get description => 'Create a remote source interface (domain/) and/or concrete implementation (data/).\n'
      'Example: simplex make:source auth\n'
      '         simplex make:source user -a (interface only)\n'
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
    bool isSnakeCase(String v) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v.trim());

    String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first.trim();
      if (!isSnakeCase(rawName)) {
        _logger.err(
          "'$rawName' is not snake_case. "
          'Please use snake_case for the source name (e.g. auth_remote_source).',
        );
        return 1;
      }
    } else if (isInteractive) {
      rawName = Input(
        prompt: 'Source name (snake_case, e.g. auth)',
        validator: (String val) {
          if (val.trim().isEmpty) return false;
          if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val.trim())) return false;
          return true;
        },
      ).interact().trim();
    } else {
      throw UsageException(
        'Source name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String sourceClass = toUpperCamelCase(rawName);
    final String sourceSnake = rawName;

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
    _logger.info(lightCyan.wrap('✨  Simplex — make:source')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Source  : ${cyan.wrap('${sourceClass}RemoteSource')}');
    _logger.info('  API     : ${cyan.wrap(apiType)}');
    _logger.info(
        '  Scope   : ${createAbstract && createImpl ? "Both" : (createAbstract ? "Abstract Only" : "Implementation Only")}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Source...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'source',
        featureName: featureName,
        featureClass: sourceClass,
        additionalVars: <String, dynamic>{
          'source_name': sourceSnake,
          'source_class': sourceClass,
          'use_graphql': apiType == 'graphql',
          'create_abstract': createAbstract,
          'create_impl': createImpl,
        },
      );
      progress.complete('${sourceClass}RemoteSource generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

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
        help: 'Only generate the abstract interface in domain.',
        negatable: false,
      )
      ..addFlag(
        'impl-only',
        help: 'Only generate the implementation in data.',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get name => 'make:source';

  @override
  String get description => 'Create a remote data source (abstract + impl) for a feature.\n'
      'Example: simplex make:source auth\n'
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
      rawName = Input(prompt: 'Source name (snake_case, e.g. auth)').interact();
    } else {
      throw UsageException(
        'Source name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String sourceSnake = snakeCase(rawName);
    final String sourceClass = toUpperCamelCase(sourceSnake);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    final bool abstractOnly = argResults?['abstract-only'] as bool? ?? false;
    final bool implOnly = argResults?['impl-only'] as bool? ?? false;

    if (abstractOnly && implOnly) {
      _logger.err('Cannot use both --abstract-only and --impl-only.');
      return 1;
    }

    final bool createAbstract = !implOnly;
    final bool createImpl = !abstractOnly;

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:source')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Source  : ${cyan.wrap(sourceClass)}');
    _logger.info('  Parts   : ${cyan.wrap('${createAbstract ? "Abstract" : ""} ${createImpl ? "Implementation" : ""}'.trim())}');
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
          'create_abstract': createAbstract,
          'create_impl': createImpl,
        },
      );
      progress.complete('$sourceClass Source generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

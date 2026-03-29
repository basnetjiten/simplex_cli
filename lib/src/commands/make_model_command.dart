// Author: Jiten Basnet
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
      'feature',
      abbr: 'f',
      help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new freezed data model for a feature.\n'
      'Example: simplex make:model User\n'
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
    final String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first;
    } else if (isInteractive) {
      rawName = Input(prompt: 'Model name (PascalCase, e.g. UserAccount)').interact();
    } else {
      throw UsageException(
        'Model name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String modelClass = toUpperCamelCase(snakeCase(rawName));
    final String modelSnake = snakeCase(rawName);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:model')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Model   : ${cyan.wrap(modelClass)}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Model...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'model',
        featureName: featureName,
        featureClass: modelClass,
        additionalVars: <String, dynamic>{
          'model_name': modelSnake,
          'model_class': modelClass,
        },
      );
      progress.complete('$modelClass generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

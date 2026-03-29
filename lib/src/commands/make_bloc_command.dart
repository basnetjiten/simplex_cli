// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeBlocCommand extends Command<int> {
  MakeBlocCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'make:bloc';

  @override
  String get description => 'Create a flutter_bloc Bloc (with Event + State) for a feature.\n'
      'Example: simplex make:bloc Auth\n'
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

    final bool isInteractive = (argResults?['interactive'] as bool?) ??
        (globalResults?['interactive'] as bool?) ??
        true;

    // ── Resolve name (positional) ────────────────────────────────────────────
    // Name must be snake_case — the generated class will be PascalCase.
    bool isSnakeCase(String v) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v.trim());

    String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first.trim();
      if (!isSnakeCase(rawName)) {
        _logger.err(
          "'$rawName' is not snake_case. "
          'Please use snake_case for the bloc name (e.g. nurse_profile, not NurseProfile).',
        );
        return 1;
      }
    } else if (isInteractive) {
      rawName = Input(
        prompt: 'Bloc name (snake_case, e.g. nurse_profile)',
        validator: (String val) {
          if (val.trim().isEmpty) return false;
          if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val.trim())) return false;
          return true;
        },
      ).interact().trim();
    } else {
      throw UsageException(
        'Bloc name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String blocClass = toUpperCamelCase(rawName);
    final String blocSnake = rawName;

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:bloc')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Bloc    : ${cyan.wrap('${blocClass}Bloc')}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Bloc...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'bloc',
        featureName: featureName,
        featureClass: blocClass,
        additionalVars: <String, dynamic>{
          'bloc_name': blocSnake,
          'bloc_class': blocClass,
        },
      );
      progress.complete('${blocClass}Bloc generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeBlocCommand extends Command<int> {
  MakeBlocCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'make:bloc';

  @override
  String get description =>
      'Create a flutter_bloc Bloc (with Event + State) for a feature.\n'
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

    // ── Resolve name (positional) ────────────────────────────────────────────
    final String rawName = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : Input(prompt: 'Bloc name (PascalCase, e.g. Auth)').interact();

    final String blocClass = toUpperCamelCase(snakeCase(rawName));
    final String blocSnake = snakeCase(rawName);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
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
      await FeatureGenerator.runBuildRunner(projectRoot, _logger);
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakeWidgetCommand extends Command<int> {
  MakeWidgetCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'make:widget';

  @override
  String get description =>
      'Create a reusable StatelessWidget inside a feature\'s presentation/widgets/ folder.\n'
      'Example: simplex make:widget AvatarCard\n'
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
        : Input(prompt: 'Widget name (PascalCase, e.g. AvatarCard)').interact();

    final String widgetClass = toUpperCamelCase(snakeCase(rawName));
    final String widgetSnake = snakeCase(rawName);

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
    );

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:widget')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Widget  : ${cyan.wrap(widgetClass)}');
    _logger.info('  Output  : ${cyan.wrap('lib/features/$featureName/presentation/widgets/$widgetSnake.dart')}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Widget...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'widget',
        featureName: featureName,
        featureClass: widgetClass,
        additionalVars: <String, dynamic>{
          'widget_name': widgetSnake,
          'widget_class': widgetClass,
        },
      );
      progress.complete('$widgetClass generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

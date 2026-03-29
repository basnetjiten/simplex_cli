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
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
      )
      ..addOption(
        'api',
        abbr: 'a',
        help: 'Implementation type (graphql/rest). Defaults to simplex.yaml default.',
        allowed: <String>['graphql', 'rest'],
      );
  }

  final Logger _logger;

  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new freezed Data Model inside a feature\'s data/models/ folder.\n'
      'Example: simplex make:model nurse_response\n'
      '         simplex make:model user_profile --api rest\n'
      'Name must be snake_case (e.g. nurse_response, not NurseResponse).\n'
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
    // Name must be snake_case — the generated class will be PascalCase.
    bool isSnakeCase(String v) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v.trim());

    String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first.trim();
      if (!isSnakeCase(rawName)) {
        _logger.err(
          "'$rawName' is not snake_case. "
          'Please use snake_case for the model name (e.g. nurse_response, not NurseResponse).',
        );
        return 1;
      }
    } else if (isInteractive) {
      rawName = Input(
        prompt: 'Model name (snake_case, e.g. nurse_response)',
        validator: (String val) {
          if (val.trim().isEmpty) return false;
          if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val.trim())) return false;
          return true;
        },
      ).interact().trim();
    } else {
      throw UsageException(
        'Model name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String modelClass = toUpperCamelCase(rawName);
    final String modelSnake = rawName;

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    final String apiType = argResults?['api'] as String? ?? config.defaultApi;

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:model')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Model   : ${cyan.wrap('${modelClass}Model')}');
    _logger.info('  API     : ${cyan.wrap(apiType)}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Data Model...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'model',
        featureName: featureName,
        featureClass: '',
        additionalVars: <String, dynamic>{
          'model_name': modelSnake,
          'model_class': modelClass,
          'use_graphql': apiType == 'graphql',
        },
      );
      progress.complete('${modelClass}Model generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

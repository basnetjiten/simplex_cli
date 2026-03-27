import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';

class MakeModelCommand extends Command<int> {
  MakeModelCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption('feature', abbr: 'f', help: 'The target feature folder (snake_case).')
      ..addOption('name', abbr: 'n', help: 'The model name (PascalCase, e.g. User).')
      ..addOption('api', abbr: 'a', help: 'Implementation type (graphql/rest).');
  }

  final Logger _logger;

  @override
  String get name => 'model';

  @override
  String get description =>
      'Create a new Data Model, Source, and Repository.\n'
      'Example: simplex make model -f auth -n Profile --api rest';

  @override
  Future<int> run() async {
    final String? projectRoot = findProjectRoot();
    if (projectRoot == null) return 1;

    final SimplexConfig? config = loadConfig(projectRoot);
    if (config == null) return 1;

    final String featureName = argResults?['feature'] as String? ??
        Input(prompt: 'Feature name (snake_case)').interact();

    final String featureClass = argResults?['name'] as String? ??
        Input(prompt: 'Model name (PascalCase)').interact();

    final String? argApi = argResults?['api'] as String?;
    final String apiType = argApi ??
        (Select(
          prompt: 'API type',
          options: <String>['graphql', 'rest'],
          initialIndex: config.defaultApi == 'rest' ? 1 : 0,
        ).interact() == 0
            ? 'graphql'
            : 'rest');

    final Progress progress = _logger.progress('Generating Data Model...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'model',
        featureName: featureName,
        featureClass: toUpperCamelCase(featureClass),
        additionalVars: <String, dynamic>{
          'use_graphql': apiType == 'graphql',
        },
      );
      progress.complete('Data Model generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

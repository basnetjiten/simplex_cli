import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';

class MakePageCommand extends Command<int> {
  MakePageCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption('feature', abbr: 'f', help: 'Feature name in snake_case.')
      ..addOption('name', abbr: 'n', help: 'Page name (PascalCase).')
      ..addFlag('paging', help: 'Enable pagination support.', defaultsTo: null);
  }

  final Logger _logger;

  @override
  String get name => 'page';

  @override
  String get description => 'Create a new Page for a feature.';

  @override
  Future<int> run() async {
    final String? projectRoot = findProjectRoot();
    if (projectRoot == null) return 1;

    final SimplexConfig? config = loadConfig(projectRoot);
    if (config == null) return 1;

    final String featureName = argResults?['feature'] as String? ??
        Input(prompt: 'Feature name (snake_case)').interact();

    final String featureClass = argResults?['name'] as String? ??
        Input(prompt: 'Page name (PascalCase)').interact();

    final bool usePaging = argResults?.wasParsed('paging') == true
        ? argResults!['paging'] as bool
        : Confirm(prompt: 'Enable pagination?', defaultValue: false).interact();

    final Progress progress = _logger.progress('Generating Page...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'page',
        featureName: featureName,
        featureClass: toUpperCamelCase(featureClass),
        additionalVars: <String, dynamic>{
          'use_paging': usePaging,
        },
      );
      progress.complete('Page generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

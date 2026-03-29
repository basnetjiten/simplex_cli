// Author: Jiten Basnet
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';

class InitCommand extends Command<int> {
  InitCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'project-name',
        abbr: 'n',
        help: 'The name of the Flutter project.',
      )
      ..addOption(
        'package-name',
        abbr: 'p',
        help: 'The Dart package name used in import paths.',
      )
      ..addOption(
        'features-path',
        help: 'Path to the features directory.',
        defaultsTo: 'lib/features',
      )
      ..addOption(
        'test-path',
        help: 'Path to the test directory.',
        defaultsTo: 'test/features',
      )
      ..addOption(
        'default-api',
        help: 'Default API type for new features.',
        allowed: <String>['graphql', 'rest'],
        defaultsTo: 'graphql',
      );
  }

  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description => 'Configure simplex_cli (e.g. simplex init)';

  @override
  Future<int> run() async {
    final String projectRoot = Directory.current.path;
    final String configPath = p.join(projectRoot, 'simplex.yaml');

    final bool isInteractive = (argResults?['interactive'] as bool?) ??
        (globalResults?['interactive'] as bool?) ??
        true;

    if (File(configPath).existsSync()) {
      if (!isInteractive) {
        _logger.info('simplex.yaml already exists. Skipping init in non-interactive mode.');
        return 0;
      }
      final bool overwrite = Confirm(
        prompt: 'simplex.yaml already exists. Overwrite?',
        defaultValue: false,
      ).interact();
      if (!overwrite) {
        _logger.info('Init cancelled.');
        return 0;
      }
    }

    _logger.info('');
    _logger.info(lightCyan.wrap('🚀  Initializing simplex_cli...')!);
    _logger.info('');

    // Derive defaults from pubspec.yaml if present
    String defaultProjectName = p.basename(projectRoot);
    final File pubspec = File(p.join(projectRoot, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final String content = pubspec.readAsStringSync();
      final RegExpMatch? match = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(content);
      if (match != null) {
        defaultProjectName = match.group(1)!.trim();
      }
    }

    final String projectName = argResults?['project-name'] as String? ??
        (isInteractive
            ? Input(
                prompt: 'Project name',
                defaultValue: defaultProjectName,
              ).interact()
            : defaultProjectName);

    final String packageName = argResults?['package-name'] as String? ??
        (isInteractive
            ? Input(
                prompt: 'Package name (used in imports)',
                defaultValue: defaultProjectName,
              ).interact()
            : defaultProjectName);

    final String featuresPath = argResults?['features-path'] as String? ??
        (isInteractive
            ? Input(
                prompt: 'Features path',
                defaultValue: 'lib/features',
              ).interact()
            : 'lib/features');

    final String testPath = argResults?['test-path'] as String? ??
        (isInteractive
            ? Input(
                prompt: 'Test path',
                defaultValue: 'test/features',
              ).interact()
            : 'test/features');

    final List<String> apiChoices = <String>['graphql', 'rest'];
    String? apiTypeMatch = argResults?['default-api'] as String?;
    final int apiIndex = apiTypeMatch != null
        ? apiChoices.indexOf(apiTypeMatch)
        : (isInteractive
            ? Select(
                prompt: 'Default API type for new features',
                options: apiChoices,
              ).interact()
            : 0);

    final SimplexConfig config = SimplexConfig(
      projectName: projectName,
      packageName: packageName,
      featuresPath: featuresPath,
      testPath: testPath,
      defaultApi: apiChoices[apiIndex],
      features: <String, FeatureConfig>{},
    );

    saveConfig(projectRoot, config);

    _logger.info('');
    _logger.success('simplex.yaml created at $configPath');
    _logger.info('');
    _logger.info('Run ${cyan.wrap('simplex make feature')} to scaffold your first feature!');
    return 0;
  }
}

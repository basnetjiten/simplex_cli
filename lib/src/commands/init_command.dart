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
        help: 'The name of the project (default: basename of project root)',
      )
      ..addOption(
        'package-name',
        help: 'The name of the package (from pubspec.yaml)',
      )
      ..addOption(
        'features-path',
        help: 'The path to store generated features (default: lib/features)',
      )
      ..addOption(
        'test-path',
        help: 'The path to store tests (default: test/features)',
      )
      ..addOption(
        'default-api',
        help: 'The default API type (graphql or rest)',
      )
      ..addFlag(
        'interactive',
        help: 'Set the default interaction preference for the CLI.\n'
            'Commands will defer to this choice if the --[no-]interactive flag is omitted.',
        defaultsTo: null,
      );
  }

  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description => 'Initialise Simplex configuration (simplex.yaml).';

  @override
  Future<int> run() async {
    final String projectRoot = Directory.current.path;
    final File configFile = File(p.join(projectRoot, 'simplex.yaml'));

    // Explicit CLI flag wins; otherwise defer to existing config/true.
    final bool isInteractive = argResults?.wasParsed('interactive') == true
        ? (argResults!['interactive'] as bool)
        : (loadConfig(projectRoot)?.interactive ?? true);

    if (configFile.existsSync() && !isInteractive) {
      _logger.info('simplex.yaml already exists. Skipping init in non-interactive mode.');
      return 0;
    }

    if (configFile.existsSync()) {
      final bool overwrite = Confirm(
        prompt: 'simplex.yaml already exists. Overwrite?',
        defaultValue: false,
      ).interact();
      if (!overwrite) return 0;
    }

    final String defaultProjectName = p.basename(projectRoot);
    final String projectName = argResults?['project-name'] as String? ??
        (isInteractive ? Input(prompt: 'Project name', defaultValue: defaultProjectName).interact() : defaultProjectName);

    final String defaultPackageName = projectName;
    final String packageName = argResults?['package-name'] as String? ??
        (isInteractive ? Input(prompt: 'Package name', defaultValue: defaultPackageName).interact() : defaultPackageName);

    final String featuresPath = argResults?['features-path'] as String? ??
        (isInteractive ? Input(prompt: 'Features path', defaultValue: 'lib/features').interact() : 'lib/features');

    final String testPath = argResults?['test-path'] as String? ??
        (isInteractive ? Input(prompt: 'Test path', defaultValue: 'test/features').interact() : 'test/features');

    final String defaultApi = argResults?['default-api'] as String? ??
        (isInteractive
            ? Select(
                prompt: 'Default API type',
                options: <String>['graphql', 'rest'],
              ).interact().let((int i) => i == 0 ? 'graphql' : 'rest')
            : 'graphql');

    final bool interactivePref = argResults?.wasParsed('interactive') == true
        ? (argResults!['interactive'] as bool)
        : (isInteractive
            ? Confirm(
                prompt: 'Should Simplex be interactive by default?',
                defaultValue: true,
              ).interact()
            : true);

    final SimplexConfig config = SimplexConfig(
      projectName: projectName,
      packageName: packageName,
      featuresPath: featuresPath,
      testPath: testPath,
      defaultApi: defaultApi,
      features: <String, FeatureConfig>{},
      interactive: interactivePref,
    );

    saveConfig(projectRoot, config);

    _logger.info('');
    _logger.success('✨  Simplex initialised! Configuration saved to simplex.yaml');
    _logger.info('');

    return 0;
  }
}

extension Let<T> on T {
  R let<R>(R Function(T) op) => op(this);
}

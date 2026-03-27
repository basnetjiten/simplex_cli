import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';

class MakeFeatureCommand extends Command<int> {
  MakeFeatureCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption('name', abbr: 'n', help: 'Feature name in snake_case (e.g. login).')
      ..addOption(
        'api',
        abbr: 'a',
        help: 'Implementation type for the data layer.',
        allowed: <String>['graphql', 'rest'],
      )
      ..addFlag('paging', help: 'Initialize the feature with PagingCubit support.')
      ..addFlag('tests', help: 'Generate placeholder test files.', defaultsTo: true);
  }

  final Logger _logger;

  @override
  String get name => 'feature';

  @override
  String get description =>
      'Scaffold a complete feature module (data, domain, and presentation).\n'
      'Example: simplex make feature -n login --api graphql --paging';

  @override
  Future<int> run() async {
    // ── Resolve project root & config ─────────────────────────────────────
    final String? projectRoot = findProjectRoot();
    if (projectRoot == null) {
      _logger.err(
        'Could not find a Flutter project root. '
        "Run 'simplex init' first, or run this command from inside your project.",
      );
      return 1;
    }

    final SimplexConfig? config = loadConfig(projectRoot);
    if (config == null) {
      _logger.err("No simplex.yaml found. Run 'simplex init' first.");
      return 1;
    }

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — Make Feature')!);
    _logger.info('');

    // ── Prompts ────────────────────────────────────────────────────────────
    final String featureName = argResults?['name'] as String? ??
        Input(
          prompt: 'Feature name (snake_case)',
          validator: (String val) {
            if (val.trim().isEmpty) return false;
            if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val.trim())) {
              return false;
            }
            return true;
          },
        ).interact();

    final String cleanName = featureName.trim();
    final String featureClass = toUpperCamelCase(cleanName);

    final List<String> apiChoices = <String>['graphql', 'rest'];
    final int defaultApiIndex = apiChoices.indexOf(config.defaultApi);
    final int apiIndex = argResults?['api'] != null
        ? apiChoices.indexOf(argResults!['api'] as String)
        : Select(
            prompt: 'API type',
            options: apiChoices,
            initialIndex: defaultApiIndex >= 0 ? defaultApiIndex : 0,
          ).interact();
    final String apiType = apiChoices[apiIndex];

    final bool usePaging = argResults?.wasParsed('paging') == true
        ? argResults!['paging'] as bool
        : Confirm(
            prompt: 'Enable pagination (PagingCubit)?',
            defaultValue: false,
          ).interact();

    final bool generateTests = argResults?.wasParsed('tests') == true
        ? argResults!['tests'] as bool
        : Confirm(
            prompt: 'Generate test stubs?',
            defaultValue: true,
          ).interact();

    // ── Check for conflicts ────────────────────────────────────────────────
    final String featureDir = p.join(projectRoot, config.featuresPath, cleanName);
    if (Directory(featureDir).existsSync()) {
      final bool overwrite = Confirm(
        prompt: "Feature '$cleanName' already exists. Overwrite?",
        defaultValue: false,
      ).interact();
      if (!overwrite) {
        _logger.info('Cancelled.');
        return 0;
      }
    }

    // ── Generate ───────────────────────────────────────────────────────────
    final Progress progress = _logger.progress('Generating $cleanName...');
    try {
      await FeatureGenerator.generate(
        projectRoot: projectRoot,
        config: config,
        featureName: cleanName,
        featureClass: featureClass,
        apiType: apiType,
        usePaging: usePaging,
        generateTests: generateTests,
      );
      progress.complete('Feature $cleanName generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    // ── Persist to feature registry ───────────────────────────────────────
    final Map<String, FeatureConfig> updatedFeatures =
        Map<String, FeatureConfig>.from(config.features)
          ..[cleanName] = FeatureConfig(api: apiType, paging: usePaging);
    saveConfig(projectRoot, config.copyWith(features: updatedFeatures));

    _logger.info('');
    _logger.info(green.wrap('✅  Done! Next steps:')!);
    _logger.info('  1. ${cyan.wrap('dart run build_runner build --delete-conflicting-outputs')}');
    _logger.info('  2. Register the route in your AutoRoute router.');
    if (apiType == 'graphql') {
      _logger.info('  3. Add your .graphql operation file and run ferry_generator.');
    }
    _logger.info('');
    return 0;
  }
}

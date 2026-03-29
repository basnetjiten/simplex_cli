// Author: Jiten Basnet
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
      ..addOption(
        'api',
        abbr: 'a',
        help: 'Implementation type for the data layer.',
        allowed: <String>['graphql', 'rest'],
      )
      ..addFlag('paging', help: 'Initialise the feature with PagingCubit support.')
      ..addFlag('tests', help: 'Generate placeholder test files.', defaultsTo: true);
  }

  final Logger _logger;

  @override
  String get name => 'make:feature';

  @override
  String get description => 'Scaffold a complete Clean Architecture feature module (data, domain, presentation).\n'
      'Example: simplex make:feature Auth\n'
      '         simplex make:feature products --api rest --paging --no-tests';

  @override
  Future<int> run() async {
    // ── Resolve project root & config ─────────────────────────────────────────
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
    _logger.info(lightCyan.wrap('✨  Simplex — make:feature')!);
    _logger.info('');

    final bool isInteractive = globalResults?['interactive'] as bool? ?? true;

    // ── Resolve name (positional) ─────────────────────────────────────────────
    final String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first;
    } else if (isInteractive) {
      rawName = Input(
        prompt: 'Feature name (PascalCase or snake_case)',
        validator: (String val) => val.trim().isNotEmpty,
      ).interact();
    } else {
      throw UsageException(
        'Feature name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String cleanName = snakeCase(rawName.trim());
    final String featureClass = toUpperCamelCase(cleanName);

    // ── API type ──────────────────────────────────────────────────────────────
    final List<String> apiChoices = <String>['graphql', 'rest'];
    final int defaultApiIndex = apiChoices.indexOf(config.defaultApi);
    final String apiType = argResults?['api'] as String? ??
        (isInteractive
            ? apiChoices[Select(
                prompt: 'API type',
                options: apiChoices,
                initialIndex: defaultApiIndex >= 0 ? defaultApiIndex : 0,
              ).interact()]
            : config.defaultApi);

    // ── Paging ────────────────────────────────────────────────────────────────
    final bool usePaging = argResults?.wasParsed('paging') == true
        ? argResults!['paging'] as bool
        : (isInteractive
            ? Confirm(
                prompt: 'Enable pagination (PagingCubit)?',
                defaultValue: false,
              ).interact()
            : false);

    // ── Tests ─────────────────────────────────────────────────────────────────
    final bool generateTests = argResults?.wasParsed('tests') == true
        ? argResults!['tests'] as bool
        : (isInteractive
            ? Confirm(
                prompt: 'Generate test stubs?',
                defaultValue: true,
              ).interact()
            : true);

    // ── Conflict check ────────────────────────────────────────────────────────
    final String featureDir = p.join(projectRoot, config.featuresPath, cleanName);
    if (Directory(featureDir).existsSync()) {
      if (!isInteractive) {
        throw StateError(
          "Feature '$cleanName' already exists. Cannot overwrite in non-interactive mode.",
        );
      }
      final bool overwrite = Confirm(
        prompt: "Feature '$cleanName' already exists. Overwrite?",
        defaultValue: false,
      ).interact();
      if (!overwrite) {
        _logger.info('Cancelled.');
        return 0;
      }
    }

    _logger.info('  Feature : ${cyan.wrap(cleanName)}');
    _logger.info('  Class   : ${cyan.wrap(featureClass)}');
    _logger.info('  API     : ${cyan.wrap(apiType)}');
    _logger.info('  Paging  : ${cyan.wrap(usePaging.toString())}');
    _logger.info('  Tests   : ${cyan.wrap(generateTests.toString())}');
    _logger.info('');

    // ── Generate ──────────────────────────────────────────────────────────────
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

    // ── Persist feature registry ──────────────────────────────────────────────
    final Map<String, FeatureConfig> updatedFeatures = Map<String, FeatureConfig>.from(config.features)
      ..[cleanName] = FeatureConfig(api: apiType, paging: usePaging);
    saveConfig(projectRoot, config.copyWith(features: updatedFeatures));

    _logger.info('');

    _logger.info(green.wrap('✅  Done! Next steps:')!);
    _logger.info(
      '  1. ${cyan.wrap('dart run build_runner build --delete-conflicting-outputs')}',
    );
    _logger.info('  2. Register the route in your AutoRoute router.');
    if (apiType == 'graphql') {
      _logger.info('  3. Add your .graphql operation file and run ferry_generator.');
    }
    _logger.info('');
    return 0;
  }
}

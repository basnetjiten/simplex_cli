// Author: Jiten Basnet
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';

class ConvertCommand extends Command<int> {
  ConvertCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'to',
        abbr: 't',
        help: 'Target API implementation type.',
        allowed: <String>['graphql', 'rest'],
        mandatory: true,
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Preview the files to be modified without writing changes.',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get name => 'convert';

  @override
  String get description => 'Convert feature data layers (e.g. simplex convert login --to rest)';

  @override
  Future<int> run() async {
    final List<String> rest = argResults?.rest ?? <String>[];
    if (rest.isEmpty) {
      _logger.err('Please specify the feature name.\n\nUsage: simplex convert <feature_name> --to [graphql|rest]');
      return 1;
    }

    final String featureName = rest.first;
    final String targetApi = argResults!['to'] as String;
    final bool dryRun = argResults!['dry-run'] as bool;

    // ── Resolve project root & config ─────────────────────────────────────
    final String? projectRoot = findProjectRoot();
    if (projectRoot == null) {
      _logger.err("Could not find a Flutter project root. Run 'simplex init' first.");
      return 1;
    }

    final SimplexConfig? config = loadConfig(projectRoot);
    if (config == null) {
      _logger.err("No simplex.yaml found. Run 'simplex init' first.");
      return 1;
    }

    // ── Check feature exists ───────────────────────────────────────────────
    final String featureDir = p.join(projectRoot, config.featuresPath, featureName);
    if (!Directory(featureDir).existsSync()) {
      _logger.err("Feature '$featureName' not found at $featureDir");
      return 1;
    }

    final FeatureConfig? currentFeatureConfig = config.features[featureName];
    final String currentApi = currentFeatureConfig?.api ?? 'unknown';
    final bool usePaging = currentFeatureConfig?.paging ?? false;

    if (currentApi == targetApi) {
      _logger.warn("Feature '$featureName' is already using $targetApi. Nothing to do.");
      return 0;
    }

    _logger.info('');
    _logger.info(lightCyan.wrap('🔄  Simplex Convert')!);
    _logger.info('  Feature : $featureName');
    _logger.info('  From    : $currentApi');
    _logger.info('  To      : $targetApi');
    _logger.info('');

    final bool isInteractive = globalResults?['interactive'] as bool? ?? true;

    if (dryRun) {
      _logger.info(yellow.wrap('🔍  Dry run — no files will be written')!);
      _logger.info('');
      _logger.info('Files that WOULD be overwritten:');
    } else {
      _logger.warn(
        "⚠️  This will overwrite the data/sources/ and data/repositories/ impl files for '$featureName'.",
      );
      if (isInteractive) {
        final bool confirmed = Confirm(
          prompt: 'Continue?',
          defaultValue: false,
        ).interact();
        if (!confirmed) {
          _logger.info('Cancelled.');
          return 0;
        }
      } else {
        _logger.info('Non-interactive mode: Proceeding with conversion.');
      }
    }

    // ── Convert (overwrite only data layer impl files) ─────────────────────
    final Progress progress =
        dryRun ? _logger.progress('Previewing changes...') : _logger.progress('Converting $featureName to $targetApi...');

    try {
      await FeatureGenerator.convertDataLayer(
        projectRoot: projectRoot,
        config: config,
        featureName: featureName,
        featureClass: _toUpperCamelCase(featureName),
        targetApi: targetApi,
        usePaging: usePaging,
        dryRun: dryRun,
        logger: _logger,
      );

      if (dryRun) {
        progress.complete('Preview complete.');
        return 0;
      }

      progress.complete('Converted $featureName to $targetApi!');
    } catch (e) {
      progress.fail('Conversion failed: $e');
      return 1;
    }

    // ── Update feature registry ────────────────────────────────────────────
    final Map<String, FeatureConfig> updatedFeatures = Map<String, FeatureConfig>.from(config.features)
      ..[featureName] = FeatureConfig(api: targetApi, paging: usePaging);
    saveConfig(projectRoot, config.copyWith(features: updatedFeatures));

    _logger.info('');
    _logger.info(green.wrap('✅  Done! Run build_runner to regenerate code:')!);
    _logger.info('  ${cyan.wrap('dart run build_runner build --delete-conflicting-outputs')}');
    _logger.info('');
    return 0;
  }

  String _toUpperCamelCase(String input) {
    return input.split('_').map((String word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join();
  }
}

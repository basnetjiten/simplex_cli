// Author: Jiten Basnet
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class RemoveCommand extends Command<int> {
  RemoveCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
      )
      ..addFlag(
        'force',
        help: 'Skip confirmation before deletion.',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get name => 'remove';

  @override
  String get description => 'Remove an existing feature module and its configuration.';

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

    // ── Resolve feature name ─────────────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String? ?? (argResults!.rest.isNotEmpty ? argResults!.rest.first : null),
      interactive: isInteractive,
    );

    if (!config.features.containsKey(featureName)) {
      _logger.err("Feature '$featureName' is not registered in simplex.yaml.");
      return 1;
    }

    final bool force = argResults?['force'] as bool? ?? false;

    if (!force && isInteractive) {
      final bool confirm = Confirm(
        prompt: "Are you sure you want to remove feature '$featureName' and its code?",
        defaultValue: false,
      ).interact();
      if (!confirm) return 0;
    }

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — remove feature')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('');

    final Progress progress = _logger.progress('Removing feature $featureName...');

    try {
      // 1. Remove from filesystem (lib)
      final String featurePath = p.join(projectRoot, config.featuresPath, featureName);
      final Directory featureDir = Directory(featurePath);
      if (featureDir.existsSync()) {
        featureDir.deleteSync(recursive: true);
        _logger.info('  Deleted: ${featureDir.path}');
      }

      // 2. Remove from filesystem (test)
      final String testPath = p.join(projectRoot, config.testPath, featureName);
      final Directory testDir = Directory(testPath);
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
        _logger.info('  Deleted: ${testDir.path}');
      }

      // 3. Remove from simplex.yaml
      final Map<String, FeatureConfig> updatedFeatures = Map<String, FeatureConfig>.from(config.features)
        ..remove(featureName);
      
      final SimplexConfig newConfig = config.copyWith(features: updatedFeatures);
      saveConfig(projectRoot, newConfig);

      progress.complete('Feature $featureName removed!');
    } catch (e) {
      progress.fail('Failed to remove feature: $e');
      return 1;
    }

    return 0;
  }
}

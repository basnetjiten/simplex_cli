// Author: Jiten Basnet
import 'dart:io';
import 'dart:isolate';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';

/// Orchestrates Mason brick generation for feature modules.
class FeatureGenerator {
  /// Generates a full feature module using the bundled 'feature' Mason brick.
  static Future<void> generate({
    required String projectRoot,
    required SimplexConfig config,
    required String featureName,
    required String featureClass,
    required String apiType,
    required bool usePaging,
    required bool generateTests,
  }) async {
    final String brickPath = await _resolveBrickPath('feature');
    final Brick brick = Brick.path(brickPath);
    final MasonGenerator generator = await MasonGenerator.fromBrick(brick);

    final DirectoryGeneratorTarget target = DirectoryGeneratorTarget(
      Directory(projectRoot),
    );

    final Map<String, dynamic> vars = <String, dynamic>{
      'feature_name': featureName,
      'feature_class': featureClass,
      'package_name': config.packageName,
      'use_graphql': apiType == 'graphql',
      'use_paging': usePaging,
      'generate_tests': generateTests,
      'created_at': DateTime.now().toString().split('.').first,
    };

    await generator.generate(
      target,
      vars: vars,
      logger: Logger(),
      fileConflictResolution: FileConflictResolution.overwrite,
    );

    // If generate_tests is false, remove the test stubs that were generated
    if (!generateTests) {
      final String testFeatureDir = p.join(projectRoot, config.testPath, featureName);
      final Directory testDir = Directory(testFeatureDir);
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    }

    // If REST, remove the graphql stub folder that the brick always creates
    if (apiType == 'rest') {
      final String graphqlDir = p.join(
        projectRoot,
        config.featuresPath,
        featureName,
        'data',
        'graphql',
      );
      final Directory dir = Directory(graphqlDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  }

  /// Converts the data layer of [featureName] to [targetApi] (graphql or rest).
  /// Only overwrites data/sources/ and data/repositories/ impl files.
  static Future<void> convertDataLayer({
    required String projectRoot,
    required SimplexConfig config,
    required String featureName,
    required String featureClass,
    required String targetApi,
    required bool usePaging,
    required bool dryRun,
    required Logger logger,
  }) async {
    final String brickPath = await _resolveBrickPath('feature');
    final Brick brick = Brick.path(brickPath);
    final MasonGenerator generator = await MasonGenerator.fromBrick(brick);

    // We generate to a temp directory, then selectively copy only data layer impls.
    final Directory tempDir = Directory.systemTemp.createTempSync('simplex_convert_');

    try {
      final DirectoryGeneratorTarget tempTarget = DirectoryGeneratorTarget(tempDir);

      final Map<String, dynamic> vars = <String, dynamic>{
        'feature_name': featureName,
        'feature_class': featureClass,
        'package_name': config.packageName,
        'use_graphql': targetApi == 'graphql',
        'use_paging': usePaging,
        'generate_tests': false,
      };

      await generator.generate(
        tempTarget,
        vars: vars,
        logger: Logger(),
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      // Files to copy from temp → real project (data layer impls only)
      final List<String> relativePathsToConvert = <String>[
        p.join('lib', 'features', featureName, 'data', 'sources', '${featureName}_remote_source_impl.dart'),
        p.join('lib', 'features', featureName, 'data', 'repositories', '${featureName}_repository_impl.dart'),
      ];

      // Handle graphql stub folder
      final String graphqlRelDir = p.join('lib', 'features', featureName, 'data', 'graphql');
      final String graphqlDest = p.join(projectRoot, graphqlRelDir);

      for (final String relPath in relativePathsToConvert) {
        final File srcFile = File(p.join(tempDir.path, relPath));
        final File destFile = File(p.join(projectRoot, relPath));

        if (dryRun) {
          logger.info('  ${destFile.path}');
          continue;
        }

        destFile.parent.createSync(recursive: true);
        srcFile.copySync(destFile.path);
      }

      if (!dryRun) {
        if (targetApi == 'graphql') {
          // Ensure graphql stub folder exists
          final String graphqlStub = p.join(tempDir.path, graphqlRelDir, '${featureName}_query.graphql');
          if (File(graphqlStub).existsSync()) {
            Directory(graphqlDest).createSync(recursive: true);
            File(graphqlStub).copySync(p.join(graphqlDest, '${featureName}_query.graphql'));
          }
        } else {
          // Remove graphql folder when converting to REST
          final Directory dir = Directory(graphqlDest);
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
          }
        }
      } else {
        if (targetApi == 'graphql') {
          logger.info('  $graphqlDest/${featureName}_query.graphql (ADD)');
        } else {
          logger.info('  $graphqlDest/ (REMOVE)');
        }
      }
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }

  /// Generates a specific component (cubit, model, page) using its brick.
  static Future<void> generateComponent({
    required String projectRoot,
    required SimplexConfig config,
    required String brickName,
    required String featureName,
    required String featureClass,
    required Map<String, dynamic> additionalVars,
  }) async {
    final String brickPath = await _resolveBrickPath(brickName);
    final Brick brick = Brick.path(brickPath);
    final MasonGenerator generator = await MasonGenerator.fromBrick(brick);

    final DirectoryGeneratorTarget target = DirectoryGeneratorTarget(
      Directory(projectRoot),
    );

    final Map<String, dynamic> vars = <String, dynamic>{
      'feature_name': featureName,
      'feature_class': featureClass,
      'package_name': config.packageName,
      'created_at': DateTime.now().toString().split('.').first,
      ...additionalVars,
    };

    await generator.generate(
      target,
      vars: vars,
      logger: Logger(),
      fileConflictResolution: FileConflictResolution.overwrite,
    );
  }

  /// Runs `dart run build_runner build --delete-conflicting-outputs` in the [projectRoot].
  static Future<void> runBuildRunner(String projectRoot, Logger logger) async {
    final Progress progress = logger.progress('Running build_runner...');
    try {
      final ProcessResult result = await Process.run(
        'dart',
        <String>['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: projectRoot,
      );

      if (result.exitCode != 0) {
        progress.fail('build_runner failed:\n${result.stderr}');
      } else {
        progress.complete('build_runner completed!');
      }
    } catch (e) {
      progress.fail('Failed to start build_runner: $e');
    }
  }

  /// Resolves path to the bundled bricks directory.
  static Future<String> _resolveBrickPath(String brickName) async {
    // Try to resolve via package URI first (best for global/snapshot execution)
    // We look for a known file in lib/ and then go up to the package root.
    final Uri packageUri = Uri.parse('package:simplex_cli/simplex_cli.dart');
    final Uri? resolvedUri = await Isolate.resolvePackageUri(packageUri);

    if (resolvedUri != null && resolvedUri.scheme == 'file') {
      final String libPath = resolvedUri.toFilePath();
      final String packageRoot = p.dirname(p.dirname(libPath)); // up from lib/
      final String candidate = p.join(packageRoot, 'bricks', brickName);
      if (Directory(candidate).existsSync()) {
        return candidate;
      }
    }

    // Fallback: search upwards from the script location (for local dev with path activation)
    final String scriptPath = Platform.script.toFilePath();
    Directory current = Directory(p.dirname(scriptPath));

    while (current.path != current.parent.path) {
      final String candidate = p.join(current.path, 'bricks', brickName);
      if (Directory(candidate).existsSync()) {
        return candidate;
      }
      current = current.parent;
    }

    // Final Fallback: relative to CWD
    final String cwdCandidate = p.join(Directory.current.path, 'bricks', brickName);
    if (Directory(cwdCandidate).existsSync()) {
      return cwdCandidate;
    }

    throw StateError(
      'Could not find bricks/$brickName directory. '
      'Checked via Isolate, upwards from $scriptPath, and in CWD (${Directory.current.path}).\n'
      'Make sure the "bricks" folder exists at the root of the simplex_cli package.',
    );
  }
}

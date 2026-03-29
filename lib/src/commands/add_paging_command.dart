// Author: Jiten Basnet
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';

class AddPagingCommand extends Command<int> {
  AddPagingCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption('feature', abbr: 'f', help: 'The feature folder containing the cubit.')
      ..addOption('name', abbr: 'n', help: 'The name of the cubit class to modify (PascalCase).');
  }

  final Logger _logger;

  @override
  String get name => 'paging';

  @override
  String get description => 'Add Simplex pagination method to an existing Cubit.\n'
      'Example: simplex add paging -f products -n List';

  @override
  Future<int> run() async {
    final String? projectRoot = findProjectRoot();
    if (projectRoot == null) {
      _logger.err('Could not find project root.');
      return 1;
    }

    final SimplexConfig? config = loadConfig(projectRoot);
    if (config == null) {
      _logger.err('No simplex.yaml found.');
      return 1;
    }

    // Explicit CLI flag wins; otherwise defer to simplex.yaml (set by `simplex init`).
    final bool isInteractive = argResults?.wasParsed('interactive') == true
        ? (argResults!['interactive'] as bool)
        : config.interactive;

    final String featureName;
    if (argResults?['feature'] != null) {
      featureName = argResults!['feature'] as String;
    } else if (isInteractive) {
      featureName = Input(prompt: 'Feature name (snake_case)').interact();
    } else {
      throw UsageException(
        'Feature name is required as an option (--feature) in non-interactive mode.',
        usage,
      );
    }

    final String cubitName;
    if (argResults?['name'] != null) {
      cubitName = argResults!['name'] as String;
    } else if (isInteractive) {
      cubitName = Input(prompt: 'Cubit name (PascalCase)').interact();
    } else {
      throw UsageException(
        'Cubit name is required as an option (--name) in non-interactive mode.',
        usage,
      );
    }

    final String className = toUpperCamelCase(cubitName);
    final String fileName = '${snakeCase(cubitName)}_cubit.dart';

    // Try standard paths
    final List<String> candidatePaths = <String>[
      p.join(projectRoot, config.featuresPath, featureName, 'presentation', 'blocs', fileName),
      p.join(projectRoot, config.featuresPath, featureName, 'presentation', 'cubit', fileName),
    ];

    File? cubitFile;
    for (final String path in candidatePaths) {
      if (File(path).existsSync()) {
        cubitFile = File(path);
        break;
      }
    }

    if (cubitFile == null) {
      _logger.err('Could not find cubit file: $fileName in feature $featureName');
      return 1;
    }

    final String content = cubitFile.readAsStringSync();

    if (content.contains('Future<(List<')) {
      _logger.warn('Cubit already appears to have a pagination method.');
      if (isInteractive) {
        if (!Confirm(prompt: 'Do you want to overwrite or add another?').interact()) {
          return 0;
        }
      } else {
        _logger.info('Non-interactive mode: Overwriting existing pagination method.');
      }
    }

    final Progress progress = _logger.progress('Injecting pagination method...');

    try {
      final String updatedContent = _injectPagingMethod(content, className);
      cubitFile.writeAsStringSync(updatedContent);
      progress.complete('Pagination method added to ${p.basename(cubitFile.path)}!');

      _logger.info('');
      _logger.info('Note: Make sure to add needed imports if not present:');
      _logger.info('  import \'package:fpdart/fpdart.dart\';');
      _logger.info('  import \'package:simplex/errors/app_error.dart\';');
    } catch (e) {
      progress.fail('Injection failed: $e');
      return 1;
    }

    return 0;
  }

  String _injectPagingMethod(String content, String className) {
    final List<String> classNameCandidates = <String>[
      className,
      '${className}Cubit',
    ];

    String? foundClass;
    for (final String candidate in classNameCandidates) {
      if (content.contains('class $candidate extends SimplexCubit')) {
        foundClass = candidate;
        break;
      }
    }

    if (foundClass == null) {
      throw Exception('Could not find class definition for $className or ${className}Cubit extending SimplexCubit');
    }

    final int lastBraceIndex = content.lastIndexOf('}');
    if (lastBraceIndex == -1) {
      throw Exception('Could not find closing brace of the file');
    }

    final String methodSnippet = '''
 
  /// Fetch function consumed by [PagingCubit].
  /// Returns a tuple of (items, nextPageKey) — pass null as nextPageKey when there are no more pages.
  Future<(List<any>, int?)> fetch$className(int page, String? search) async {
    // TODO: update [any] with your model and use your repository
    // final Either<AppError, any> response = await _repository.get$className();
    // return response.fold(
    //   (AppError error) {
    //     emit(state.copyWith(status: BlocStatus.error(error: error.toString())));
    //     throw error;
    //   },
    //   (any data) {
    //     emit(state.copyWith(status: BlocStatus.success(apiData: ApiData<any>.fromData(data: data))));
    //     return (<any>[data], null);
    //   },
    // );
    throw UnimplementedError('fetch$className not implemented');
  }
''';

    return content.substring(0, lastBraceIndex) + methodSnippet + content.substring(lastBraceIndex);
  }
}

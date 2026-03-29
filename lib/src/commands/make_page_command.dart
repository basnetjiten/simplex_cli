// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:interact/interact.dart' hide Progress;
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/config/simplex_config.dart';
import 'package:simplex_cli/src/generators/feature_generator.dart';
import 'package:simplex_cli/src/utils/case_utils.dart';
import 'package:simplex_cli/src/utils/path_aware_resolver.dart';

class MakePageCommand extends Command<int> {
  MakePageCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Target feature name (snake_case). Inferred from CWD if omitted.',
      )
      ..addFlag(
        'paging',
        help: 'Wrap the page body with PagingCubit.',
        defaultsTo: null,
      );
  }

  final Logger _logger;

  @override
  String get name => 'make:page';

  @override
  String get description => 'Create a new Page widget for a feature.\n'
      'Example: simplex make:page login\n'
      '         simplex make:page product_list --paging\n'
      'Path-aware: run from inside a feature folder to skip the feature prompt.';

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

    final bool isInteractive = (argResults?['interactive'] as bool?) ??
        (globalResults?['interactive'] as bool?) ??
        true;

    // ── Resolve name (positional) ────────────────────────────────────────────
    final String rawName;
    if (argResults!.rest.isNotEmpty) {
      rawName = argResults!.rest.first;
    } else if (isInteractive) {
      rawName = Input(prompt: 'Page name (snake_case, e.g. login)').interact();
    } else {
      throw UsageException(
        'Page name is required as a positional argument in non-interactive mode.',
        usage,
      );
    }

    final String pageClass = toUpperCamelCase(snakeCase(rawName));

    // ── Resolve feature (path-aware) ─────────────────────────────────────────
    final String featureName = resolveFeatureName(
      config: config,
      projectRoot: projectRoot,
      argValue: argResults?['feature'] as String?,
      interactive: isInteractive,
    );

    final bool usePaging = argResults?.wasParsed('paging') == true
        ? argResults!['paging'] as bool
        : (isInteractive
            ? Confirm(
                prompt: 'Enable pagination (PagingCubit)?',
                defaultValue: false,
              ).interact()
            : false);

    _logger.info('');
    _logger.info(lightCyan.wrap('✨  Simplex — make:page')!);
    _logger.info('  Feature : ${cyan.wrap(featureName)}');
    _logger.info('  Page    : ${cyan.wrap('${pageClass}Page')}');
    _logger.info('');

    final Progress progress = _logger.progress('Generating Page...');
    try {
      await FeatureGenerator.generateComponent(
        projectRoot: projectRoot,
        config: config,
        brickName: 'page',
        featureName: featureName,
        featureClass: pageClass,
        additionalVars: <String, dynamic>{
          'use_paging': usePaging,
        },
      );
      progress.complete('${pageClass}Page generated!');
    } catch (e) {
      progress.fail('Generation failed: $e');
      return 1;
    }

    return 0;
  }
}

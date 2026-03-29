// Author: Jiten Basnet
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/commands/add_command.dart';
import 'package:simplex_cli/src/commands/convert_command.dart';
import 'package:simplex_cli/src/commands/init_command.dart';
import 'package:simplex_cli/src/commands/make_bloc_command.dart';
import 'package:simplex_cli/src/commands/make_cubit_command.dart';
import 'package:simplex_cli/src/commands/make_feature_command.dart';
import 'package:simplex_cli/src/commands/make_model_command.dart';
import 'package:simplex_cli/src/commands/make_page_command.dart';
import 'package:simplex_cli/src/commands/make_repo_command.dart';
import 'package:simplex_cli/src/commands/make_source_command.dart';

// ---------------------------------------------------------------------------
// Command aliases: maps every known "make:xxx" token to its Command factory.
// ---------------------------------------------------------------------------
const Map<String, String> _colonAliases = <String, String>{
  'make:feature': 'make:feature',
  'make:cubit': 'make:cubit',
  'make:bloc': 'make:bloc',
  'make:model': 'make:model',
  'make:page': 'make:page',
  'make:repo': 'make:repo',
  'make:source': 'make:source',
};

class SimplexRunner {
  static Future<void> run(List<String> args) async {
    final Logger logger = Logger();

    // ── Build a flat CommandRunner with colon-keyed command names ────────────
    // The `args` package does not support literal colons in command names when
    // using CommandRunner.run(), so we intercept the first token, rewrite it
    // if it matches a known alias, and delegate manually to the right Command.
    // ─────────────────────────────────────────────────────────────────────────

    final Map<String, Command<int>> registry = <String, Command<int>>{
      'init': InitCommand(logger: logger),
      'convert': ConvertCommand(logger: logger),
      'add': AddCommand(logger: logger),
      // Artisan-style colon commands (stored under their full "make:xxx" key)
      'make:feature': MakeFeatureCommand(logger: logger),
      'make:cubit': MakeCubitCommand(logger: logger),
      'make:bloc': MakeBlocCommand(logger: logger),
      'make:model': MakeModelCommand(logger: logger),
      'make:page': MakePageCommand(logger: logger),
      'make:repo': MakeRepoCommand(logger: logger),
      'make:source': MakeSourceCommand(logger: logger),
    };

    // ── Short-circuit for zero args or global help ───────────────────────────
    if (args.isEmpty || args.first == '--help' || args.first == '-h') {
      _printHelp(logger);
      exit(0);
    }

    final String firstToken = args.first;

    // ── Dispatch colon commands ──────────────────────────────────────────────
    if (firstToken.contains(':') && _colonAliases.containsKey(firstToken)) {
      final Command<int> cmd = registry[firstToken]!;
      final List<String> rest = args.skip(1).toList();

      // Wire up a minimal CommandRunner so the Command's argParser is honoured
      final CommandRunner<int> runner = CommandRunner<int>(
        'simplex',
        cmd.description,
      )..addCommand(cmd);

      try {
        // Re-map "make:cubit Auth" → "make:cubit Auth" (command name as-is)
        // CommandRunner.run expects [commandName, ...rest]
        final int? code = await runner.run(<String>[firstToken, ...rest]);
        exit(code ?? 0);
      } on UsageException catch (e) {
        logger.err(e.message);
        logger.info('');
        logger.info(e.usage);
        exit(64);
      } catch (e) {
        logger.err('$e');
        exit(1);
      }
    }

    // ── Dispatch legacy multi-word commands (init, convert, add) ────────────
    final CommandRunner<int> runner = CommandRunner<int>(
      'simplex',
      'Scaffold Clean Architecture modules for Flutter.',
    )
      ..addCommand(InitCommand(logger: logger))
      ..addCommand(ConvertCommand(logger: logger))
      ..addCommand(AddCommand(logger: logger));

    try {
      final int? exitCode = await runner.run(args);
      exit(exitCode ?? 0);
    } on UsageException catch (e) {
      logger.err(e.message);
      logger.info('');
      logger.info(e.usage);
      exit(64);
    } catch (e) {
      logger.err('$e');
      exit(1);
    }
  }

  static void _printHelp(Logger logger) {
    logger.info('');
    logger.info(lightCyan.wrap('✨  Simplex CLI — Clean Architecture Scaffolder')!);
    logger.info('');
    logger.info(styleBold.wrap('USAGE')!);
    logger.info('  simplex <command> [arguments]');
    logger.info('');
    logger.info(styleBold.wrap('SCAFFOLD COMMANDS')!);
    logger.info(
      '  ${cyan.wrap('simplex make:feature')}    Auth              — scaffold full feature module',
    );
    logger.info(
      '  ${cyan.wrap('simplex make:cubit')}      Counter           — create a SimplexCubit',
    );
    logger.info(
      '  ${cyan.wrap('simplex make:bloc')}       Auth              — create a SimplexBloc',
    );
    logger.info(
      '  ${cyan.wrap('simplex make:model')}      User              — create a freezed data model',
    );
    logger.info(
      '  ${cyan.wrap('simplex make:page')}       Login             — create a page widget',
    );
    logger.info(
      '  ${cyan.wrap('simplex make:repo')}       user              — create repo abstract + impl',
    );
    logger.info(
      '  ${cyan.wrap('simplex make:repo')}       user              — create repo abstract + impl',
    );
    logger.info(
      '  ${cyan.wrap('simplex make:source')}     auth              — create source abstract + impl',
    );
    logger.info('');
    logger.info(styleBold.wrap('OTHER COMMANDS')!);
    logger.info('  ${cyan.wrap('simplex init')}                         — initialise simplex.yaml');
    logger.info('  ${cyan.wrap('simplex convert <feature> --to rest')}  — convert data layer');
    logger.info('  ${cyan.wrap('simplex add paging')}                   — add paging support');
    logger.info('');
    logger.info(
      darkGray.wrap(
        'Tip: run any command from inside a feature folder and the\n'
        '     feature name will be detected automatically from your CWD.',
      )!,
    );
    logger.info('');
  }
}

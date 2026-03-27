import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/commands/init_command.dart';
import 'package:simplex_cli/src/commands/make_command.dart';
import 'package:simplex_cli/src/commands/convert_command.dart';
import 'package:simplex_cli/src/commands/add_command.dart';

class SimplexRunner {
  static Future<void> run(List<String> args) async {
    final Logger logger = Logger();

    final CommandRunner<int> runner = CommandRunner<int>(
      'simplex',
      'A CLI tool to scaffold Clean Architecture feature modules for Flutter Simplex projects.',
    )
      ..addCommand(InitCommand(logger: logger))
      ..addCommand(MakeCommand(logger: logger))
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
}

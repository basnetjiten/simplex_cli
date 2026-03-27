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
      'Scaffold Clean Architecture modules for Flutter.\n\n'
      'COMMANDS:\n'
      '  init              | simplex init\n'
      '  make feature      | simplex make feature -n login\n'
      '  make cubit        | simplex make cubit -f products -n List --paging\n'
      '  make model        | simplex make model -f products -n User\n'
      '  make page         | simplex make page -f products -n Settings\n'
      '  add paging        | simplex add paging -f products -n List\n'
      '  convert           | simplex convert login --to rest',
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

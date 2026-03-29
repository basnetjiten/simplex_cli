// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/commands/add_paging_command.dart';

class AddCommand extends Command<int> {
  AddCommand({required Logger logger}) {
    addSubcommand(AddPagingCommand(logger: logger));
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Add extra features or capabilities to an existing module.';
}

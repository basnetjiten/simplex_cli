// Author: Jiten Basnet
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/commands/add_paging_command.dart';

class AddCommand extends Command<int> {
  AddCommand({required Logger logger}) : _logger = logger {
    addSubcommand(AddPagingCommand(logger: logger));
  }

  final Logger _logger;

  @override
  String get name => 'add';

  @override
  String get description => 'Inject logic into components (e.g. simplex add paging -f products)';

  @override
  Future<int> run() async {
    _logger.info(usage);
    return 0;
  }
}

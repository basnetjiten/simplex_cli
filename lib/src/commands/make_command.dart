import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/commands/make_feature_command.dart';
import 'package:simplex_cli/src/commands/make_cubit_command.dart';
import 'package:simplex_cli/src/commands/make_model_command.dart';
import 'package:simplex_cli/src/commands/make_page_command.dart';

class MakeCommand extends Command<int> {
  MakeCommand({required Logger logger}) : _logger = logger {
    addSubcommand(MakeFeatureCommand(logger: logger));
    addSubcommand(MakeCubitCommand(logger: logger));
    addSubcommand(MakeModelCommand(logger: logger));
    addSubcommand(MakePageCommand(logger: logger));
  }

  final Logger _logger;

  @override
  String get name => 'make';

  @override
  String get description =>
      'A suite of commands for scaffolding feature modules and components.\n'
      'Example: simplex make feature -n login';

  @override
  Future<int> run() async {
    _logger.info(usage);
    return 0;
  }
}

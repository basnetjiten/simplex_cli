import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:simplex_cli/src/commands/make_feature_command.dart';

class MakeCommand extends Command<int> {
  MakeCommand({required Logger logger}) : _logger = logger {
    addSubcommand(MakeFeatureCommand(logger: logger));
  }

  final Logger _logger;

  @override
  String get name => 'make';

  @override
  String get description => 'Generate files from templates (e.g. feature modules).';

  @override
  Future<int> run() async {
    _logger.info(usage);
    return 0;
  }
}

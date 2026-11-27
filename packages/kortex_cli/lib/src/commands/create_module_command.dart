import 'dart:io';

import '../utils/cli_command.dart';
import '../utils/cli_file_writer.dart';
import '../templates/controller_template.dart';
import '../templates/controller_test_template.dart';
import '../templates/module_routes_template.dart';
import '../utils/naming.dart';
import '../templates/page_template.dart';

class CreateModuleCommand implements IKortexCliCommand {
  const CreateModuleCommand(this._writer);

  final ICliFileWriter _writer;

  @override
  String get name => 'module';

  @override
  String get usage => 'kortex module <module_name>          Cria fatia vertical em lib/modules/<module_name>/';

  @override
  int execute(List<String> args, Directory workingDirectory) {
    if (args.isEmpty) return 64;
    final moduleName = args.first;
    final pascal = toPascalCase(moduleName);
    final base = 'lib/modules/$moduleName';
    _writer.writeFile(workingDirectory, '$base/ui/${moduleName}_controller.dart', controllerTemplate(pascal));
    _writer.writeFile(workingDirectory, '$base/ui/${moduleName}_page.dart', pageTemplate(pascal, moduleName));
    _writer.writeFile(workingDirectory, '$base/ui/${moduleName}_routes.dart', moduleRoutesTemplate(pascal, moduleName));
    _writer.writeFile(workingDirectory, 'test/modules/$moduleName/${moduleName}_controller_test.dart', controllerTestTemplate(pascal, moduleName));
    for (final sub in ['domain', 'data', 'features']) {
      _writer.ensureDir(workingDirectory, '$base/$sub');
    }
    stdout.writeln('Modulo "$moduleName" criado em $base');
    return 0;
  }
}

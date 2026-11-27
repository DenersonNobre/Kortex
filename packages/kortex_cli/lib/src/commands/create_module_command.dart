import 'dart:io';

import '../cli_command.dart';
import '../cli_file_writer.dart';
import '../templates/kortex_templates.dart';

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
    final pascal = KortexTemplates.toPascalCase(moduleName);
    final base = 'lib/modules/$moduleName';
    _writer.writeFile(workingDirectory, '$base/ui/${moduleName}_controller.dart', KortexTemplates.controller(pascal));
    _writer.writeFile(workingDirectory, '$base/ui/${moduleName}_page.dart', KortexTemplates.page(pascal, moduleName));
    _writer.writeFile(workingDirectory, '$base/ui/${moduleName}_routes.dart', KortexTemplates.moduleRoutes(pascal, moduleName));
    _writer.writeFile(workingDirectory, 'test/modules/$moduleName/${moduleName}_controller_test.dart', KortexTemplates.controllerTest(pascal, moduleName));
    for (final sub in ['domain', 'data', 'features']) {
      _writer.ensureDir(workingDirectory, '$base/$sub');
    }
    stdout.writeln('Modulo "$moduleName" criado em $base');
    return 0;
  }
}

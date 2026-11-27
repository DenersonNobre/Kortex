import 'dart:io';

import '../cli_command.dart';
import '../cli_file_writer.dart';
import '../templates/controller_template.dart';
import '../templates/naming.dart';
import '../templates/page_template.dart';

class CreatePageCommand implements IKortexCliCommand {
  const CreatePageCommand(this._writer);

  final ICliFileWriter _writer;

  @override
  String get name => 'page';

  @override
  String get usage => 'kortex page <module_name> <page>     Cria page + controller em lib/modules/<module_name>/ui/';

  @override
  int execute(List<String> args, Directory workingDirectory) {
    if (args.length < 2) return 64;
    final moduleName = args[0];
    final pageName = args[1];
    final pascal = toPascalCase(pageName);
    final base = 'lib/modules/$moduleName/ui';
    _writer.writeFile(workingDirectory, '$base/${pageName}_controller.dart', controllerTemplate(pascal));
    _writer.writeFile(workingDirectory, '$base/${pageName}_page.dart', pageTemplate(pascal, pageName));
    stdout.writeln('Page "$pageName" criada em $base');
    return 0;
  }
}

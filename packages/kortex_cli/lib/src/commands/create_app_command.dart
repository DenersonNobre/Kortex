import 'dart:io';

import '../cli_command.dart';
import '../cli_file_writer.dart';
import '../templates/app_pages_template.dart';
import '../templates/app_routes_template.dart';
import '../templates/app_template.dart';
import '../templates/app_test_template.dart';
import '../templates/main_template.dart';
import '../templates/pubspec_template.dart';

class CreateAppCommand implements IKortexCliCommand {
  const CreateAppCommand(this._writer);

  final ICliFileWriter _writer;

  @override
  String get name => 'create';

  @override
  String get usage => 'kortex create <app_name>             Cria estrutura base em <app_name>/';

  @override
  int execute(List<String> args, Directory workingDirectory) {
    if (args.isEmpty) return 64;
    final appName = args.first;
    final root = Directory('${workingDirectory.path}${Platform.pathSeparator}$appName');
    _writer.writeFile(root, 'pubspec.yaml', pubspecTemplate(appName));
    _writer.writeFile(root, 'lib/main.dart', mainTemplate());
    _writer.writeFile(root, 'lib/app/app.dart', appTemplate(appName));
    _writer.writeFile(root, 'lib/app/routes/app_routes.dart', appRoutesTemplate());
    _writer.writeFile(root, 'lib/app/routes/app_pages.dart', appPagesTemplate());
    _writer.writeFile(root, 'test/widget_test.dart', appTestTemplate());
    _writer.ensureDir(root, 'lib/core');
    _writer.ensureDir(root, 'lib/modules');
    stdout.writeln('App "$appName" criado em ${root.path}');
    return 0;
  }
}

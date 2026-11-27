/// Pure-Dart CLI for scaffolding Kortex apps and modules.
library;

import 'dart:io';

import 'src/utils/cli_command.dart';
import 'src/utils/cli_file_writer.dart';
import 'src/commands/create_app_command.dart';
import 'src/commands/create_module_command.dart';
import 'src/commands/create_page_command.dart';

/// Executes the `kortex` CLI with [args] in [workingDirectory].
int runKortexCli(
  List<String> args,
  Directory workingDirectory, {
  ICliFileWriter writer = const DiskCliFileWriter(),
}) {
  final commands = <String, IKortexCliCommand>{
    for (final cmd in [
      CreateAppCommand(writer),
      CreateModuleCommand(writer),
      CreatePageCommand(writer),
    ])
      cmd.name: cmd,
  };

  if (args.isEmpty || args.first == 'help' || args.first == '--help') {
    _printUsage(commands.values);
    return 0;
  }

  final command = commands[args.first];
  if (command == null) {
    stderr.writeln('Comando invalido: ${args.join(' ')}');
    _printUsage(commands.values);
    return 64;
  }

  final code = command.execute(args.sublist(1), workingDirectory);
  if (code == 64) {
    stderr.writeln('Argumentos insuficientes para "${command.name}".');
    _printUsage(commands.values);
  }
  return code;
}

void _printUsage(Iterable<IKortexCliCommand> commands) {
  stdout.writeln('kortex_cli — Scaffolding para apps Kortex');
  stdout.writeln('');
  stdout.writeln('Uso:');
  for (final cmd in commands) {
    stdout.writeln('  ${cmd.usage}');
  }
  stdout.writeln('  kortex help                          Exibe esta ajuda');
}

import 'dart:io';

import 'package:kortex_cli/kortex_cli.dart';

void main(List<String> args) {
  final exitCodeValue = runKortexCli(args, Directory.current);
  exit(exitCodeValue);
}

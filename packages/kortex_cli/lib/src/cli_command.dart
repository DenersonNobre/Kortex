import 'dart:io';

/// Contrato de comando do `kortex_cli` (OCP / ISP).
abstract class IKortexCliCommand {
  String get name;
  String get usage;
  int execute(List<String> args, Directory workingDirectory);
}

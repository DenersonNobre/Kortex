import 'dart:io';

/// Porta de escrita no sistema de arquivos (DIP).
abstract class ICliFileWriter {
  void writeFile(Directory root, String relativePath, String content);
  void ensureDir(Directory root, String relativePath);
}

/// Implementacao padrao em disco usando `dart:io`.
class DiskCliFileWriter implements ICliFileWriter {
  const DiskCliFileWriter();

  @override
  void writeFile(Directory root, String relativePath, String content) {
    final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
    final file = File('${root.path}${Platform.pathSeparator}$normalized');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  @override
  void ensureDir(Directory root, String relativePath) {
    final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
    Directory('${root.path}${Platform.pathSeparator}$normalized')
        .createSync(recursive: true);
  }
}

import 'dart:async';
import 'dart:io';

import 'log_entry.dart';

/// Porta [ILogSink] e adaptadores de destino do logging.
abstract class ILogSink {
  void write(LogEntry entry);
}

class NullLogSink implements ILogSink {
  const NullLogSink();

  @override
  void write(LogEntry entry) {}
}

class FunctionLogSink implements ILogSink {
  FunctionLogSink(this._onEntry);

  final void Function(LogEntry entry) _onEntry;

  @override
  void write(LogEntry entry) => _onEntry(entry);
}

class MemoryLogSink implements ILogSink {
  final List<LogEntry> entries = <LogEntry>[];

  bool get isEmpty => entries.isEmpty;

  List<LogEntry> byLevel(LogLevel level) =>
      entries.where((entry) => entry.level == level).toList();

  void clear() => entries.clear();

  @override
  void write(LogEntry entry) => entries.add(entry);
}


/// Sink em arquivo local com rotacao simples por tamanho maximo (`maxBytes`).
class FileLogSink implements ILogSink {
  FileLogSink(this.file, {this.maxBytes = 1024 * 1024});

  final File file;
  final int maxBytes;

  @override
  void write(LogEntry entry) {
    file.parent.createSync(recursive: true);
    if (file.existsSync() && file.lengthSync() >= maxBytes) {
      final backup = File('${file.path}.1');
      if (backup.existsSync()) backup.deleteSync();
      file.renameSync(backup.path);
    }
    final line =
        '${entry.timestamp.toIso8601String()} [${entry.level.name}] ${entry.scope}: ${entry.message}\n';
    file.writeAsStringSync(line, mode: FileMode.append);
  }
}

/// Sink com buffer em lote para envio assincrono de telemetria.
class BufferedLogSink implements ILogSink {
  BufferedLogSink({
    required this.onFlush,
    this.batchSize = 20,
  });

  final Future<void> Function(List<LogEntry> entries) onFlush;
  final int batchSize;
  final List<LogEntry> _buffer = <LogEntry>[];

  @override
  void write(LogEntry entry) {
    _buffer.add(entry);
    if (_buffer.length >= batchSize) {
      unawaited(flush());
    }
  }

  /// Descarrega o lote pendente imediatamente.
  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<LogEntry>.unmodifiable(_buffer);
    _buffer.clear();
    await onFlush(batch);
  }
}

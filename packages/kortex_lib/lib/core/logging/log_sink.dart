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

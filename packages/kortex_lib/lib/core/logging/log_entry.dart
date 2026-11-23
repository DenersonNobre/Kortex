// LogLevel e LogEntry — modelo imutável de entrada de log.
//
// SRP: representar severidade e carregar os dados de uma ocorrência (nível,
// escopo, mensagem, metadata, erro e timestamp) para os sinks/formatters.
// Timestamp sempre UTC (ISO-8601) — invariante cross-locale do ecossistema.

enum LogLevel { trace, debug, info, warn, error, fatal }

class LogEntry {
  LogEntry({
    required this.level,
    required this.scope,
    required this.message,
    this.metadata,
    this.error,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  final LogLevel level;
  final String scope;
  final String message;
  final Map<String, Object?>? metadata;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
}

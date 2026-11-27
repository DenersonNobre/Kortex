// Formatters de log e o decorator FormattedLogSink.
//
// SRP: converter LogEntry em string — [TextLogFormatter] (texto anotado,
// legível em console/arquivo) ou [JsonLogFormatter] (estruturado para
// ingestão/remoto). [FormattedLogSink] filtra por threshold e entrega a linha
// formatada a um alvo `void Function(String)`.
//
// Invariante: datas em ISO-8601 UTC e decimais sem locale — nunca formatar
// com separadores dependentes de idioma (evita corromper ingestão).

import 'dart:convert';

import 'log_entry.dart';
import 'log_sink.dart';

abstract class ILogFormatter {
  String format(LogEntry entry);
}

class TextLogFormatter implements ILogFormatter {
  const TextLogFormatter();

  @override
  String format(LogEntry entry) {
    final meta = entry.metadata == null || entry.metadata!.isEmpty
        ? ''
        : ' ${entry.metadata}';
    final erro = entry.error == null ? '' : ' -> ${entry.error}';
    final nivel = entry.level.name.toUpperCase();
    return '${entry.timestamp.toIso8601String()} [$nivel] '
        '${entry.scope}: ${entry.message}$meta$erro';
  }
}

class JsonLogFormatter implements ILogFormatter {
  const JsonLogFormatter();

  @override
  String format(LogEntry entry) {
    final mapa = <String, Object?>{
      'ts': entry.timestamp.toIso8601String(),
      'level': entry.level.name,
      'scope': entry.scope,
      'message': entry.message,
      if (entry.metadata != null && entry.metadata!.isNotEmpty)
        'metadata': _jsonSafe(entry.metadata),
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stackTrace': entry.stackTrace.toString(),
    };
    return jsonEncode(mapa);
  }

  /// Coage valores não primitivos para tipos JSON nativos (Date→String, etc.)
  /// — evita `jsonEncode` lançando em metadata arbitrário.
  Object? _jsonSafe(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry<String, Object?>('$key', _jsonSafe(item)),
      );
    }
    if (value is Iterable) return value.map(_jsonSafe).toList();
    return value.toString();
  }
}

class FormattedLogSink implements ILogSink {
  FormattedLogSink(
    this._target, {
    this.formatter = const TextLogFormatter(),
    this.threshold = LogLevel.debug,
  });

  final void Function(String line) _target;
  final ILogFormatter formatter;
  final LogLevel threshold;

  @override
  void write(LogEntry entry) {
    if (entry.level.index < threshold.index) {
      return;
    }
    _target(formatter.format(entry));
  }
}


/// Formatter com cores ANSI e destaque em negrito por [LogLevel] para console.
class AnsiTextLogFormatter implements ILogFormatter {
  const AnsiTextLogFormatter({this.inner = const TextLogFormatter()});

  final ILogFormatter inner;

  @override
  String format(LogEntry entry) {
    final code = switch (entry.level) {
      LogLevel.trace => '\x1B[90m',
      LogLevel.debug => '\x1B[36m',
      LogLevel.info => '\x1B[32m',
      LogLevel.warn => '\x1B[33m',
      LogLevel.error => '\x1B[31m',
      LogLevel.fatal => '\x1B[1;31m',
    };
    return '$code\x1B[1m[${entry.level.name.toUpperCase()}]\x1B[22m ${inner.format(entry)}\x1B[0m';
  }
}

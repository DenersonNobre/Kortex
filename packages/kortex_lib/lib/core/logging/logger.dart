// Logger, LogRedactor e LogManager — emissão de logs do ecossistema.
//
// SRP:
//   - [LogRedactor] — mascara chaves sensíveis em metadata e credenciais
//     `chave=valor`/`chave: valor` em mensagens;
//   - [Logger] — emite entradas com escopo, threshold e redação;
//   - [LogManager] — Facade singleton: configura sinks/threshold/redator e
//     loggers memoizados por escopo. Sem `configure`, opera como no-op seguro.

import 'log_entry.dart';
import 'log_sink.dart';

class LogRedactor {
  const LogRedactor({
    this._sensitiveKeys = defaultSensitiveKeys,
    this.mask = '***',
  });

  /// Chaves tratadas como sensíveis por padrão (formas comuns de credencial).
  static const Set<String> defaultSensitiveKeys = {
    'senha',
    'password',
    'passwd',
    'secret',
    'token',
    'apikey',
    'secretkey',
    'authorization',
    'credentials',
  };

  final Set<String> _sensitiveKeys;
  final String mask;

  static String _norm(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[_-]'), '');

  bool _isSensitiveKey(String key) {
    final normalizedKey = _norm(key);
    return _sensitiveKeys.any(
      (sensitive) => normalizedKey.contains(_norm(sensitive)),
    );
  }

  /// Mascara valores das chaves sensíveis presentes em [metadata]. Sempre
  /// devolve um Map (vazio quando [metadata] é nulo/vazio).
  Map<String, Object?> redactMap(Map<String, Object?>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return const {};
    }
    final output = <String, Object?>{};
    metadata.forEach((key, value) {
      output[key] = _isSensitiveKey(key) ? mask : value;
    });
    return output;
  }

  /// Mascara credenciais em mensagens de texto no formato `chave=valor` ou
  /// `chave: valor`. Não mascara texto solto, que é ambíguo.
  String redactMessage(String message) {
    final alternatives =
        _sensitiveKeys.map(_norm).map(RegExp.escape).toSet().toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      '\\b(${alternatives.join('|')})\\b(\\s*[:=]\\s*)(\\S+)',
      caseSensitive: false,
    );
    return message.replaceAllMapped(
      pattern,
      (match) => '${match.group(1)}${match.group(2)}$mask',
    );
  }
}

class Logger {
  Logger(
    this._sink, {
    required this.scope,
    this.redactor,
    this.threshold = LogLevel.debug,
  });

  final ILogSink _sink;
  final String scope;
  final LogRedactor? redactor;
  final LogLevel threshold;

  void trace(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.trace,
    message,
    metadata: metadata,
    error: error,
    stackTrace: stackTrace,
  );

  void debug(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.debug,
    message,
    metadata: metadata,
    error: error,
    stackTrace: stackTrace,
  );

  void info(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.info,
    message,
    metadata: metadata,
    error: error,
    stackTrace: stackTrace,
  );

  void warn(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.warn,
    message,
    metadata: metadata,
    error: error,
    stackTrace: stackTrace,
  );

  void error(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.error,
    message,
    metadata: metadata,
    error: error,
    stackTrace: stackTrace,
  );

  void fatal(
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.fatal,
    message,
    metadata: metadata,
    error: error,
    stackTrace: stackTrace,
  );

  void _emit(
    LogLevel level,
    String message, {
    Map<String, Object?>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < threshold.index) {
      return;
    }
    final activeRedactor = redactor;
    _sink.write(
      LogEntry(
        level: level,
        scope: scope,
        message: activeRedactor == null
            ? message
            : activeRedactor.redactMessage(message),
        metadata: activeRedactor == null || metadata == null
            ? metadata
            : activeRedactor.redactMap(metadata),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

class LogManager {
  LogManager._();

  static final LogManager instance = LogManager._();

  static Logger get root => instance.rootLogger;
  static Logger scope(String scope) => instance.logger(scope);

  /// Configura sinks/threshold/redator. Com [sink] nulo aplica [NullLogSink]
  /// (reset) — seguro chamar entre testes e na inicialização do app.
  static void configure({
    ILogSink? sink,
    LogRedactor? redactor,
    LogLevel threshold = LogLevel.info,
  }) => instance._configure(sink, redactor, threshold);

  ILogSink? _sink;
  LogRedactor? _redactor;
  LogLevel _threshold = LogLevel.info;
  final Map<String, Logger> _scopes = {};

  void _configure(ILogSink? sink, LogRedactor? redactor, LogLevel threshold) {
    _sink = sink ?? const NullLogSink();
    _redactor = redactor;
    _threshold = threshold;
    _scopes.clear();
  }

  Logger get rootLogger => _build('root');

  Logger logger(String scope) =>
      _scopes.putIfAbsent(scope, () => _build(scope));

  Logger _build(String scope) => Logger(
    _sink ?? const NullLogSink(),
    scope: scope,
    redactor: _redactor,
    threshold: _threshold,
  );
}

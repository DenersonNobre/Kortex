import 'dart:convert';

import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('LogEntry e formatters', () {
    test('timestamp padrão é UTC', () {
      final entry = LogEntry(
        level: LogLevel.info,
        scope: 'core',
        message: 'ready',
      );

      expect(entry.timestamp.isUtc, isTrue);
    });

    test('JSON formatter produz registro JSON com campos canônicos', () {
      final formatter = const JsonLogFormatter();
      final line = formatter.format(
        LogEntry(
          timestamp: DateTime.utc(2026, 9, 24, 1, 2, 3),
          level: LogLevel.warn,
          scope: 'core',
          message: 'warning',
          metadata: const {'attempt': 2},
        ),
      );
      final decoded = jsonDecode(line) as Map<String, dynamic>;

      expect(decoded['level'], 'warn');
      expect(decoded['scope'], 'core');
      expect(decoded['message'], 'warning');
      expect(decoded['metadata'], {'attempt': 2});
    });
  });

  group('LogRedactor', () {
    test('mascara credenciais em metadata e mensagens', () {
      const redactor = LogRedactor();

      expect(
        redactor.redactMap(const {'password': 'secret'})['password'],
        '***',
      );
      expect(redactor.redactMessage('token=abc'), 'token=***');
    });
  });

  group('Logger e sinks', () {
    test('aplica threshold e envia ao sink em memória', () {
      final sink = MemoryLogSink();
      final logger = Logger(
        sink,
        scope: 'core',
        threshold: LogLevel.warn,
        redactor: const LogRedactor(),
      );

      logger.info('ignored');
      logger.error('failed token=secret');

      expect(sink.entries, hasLength(1));
      expect(sink.entries.single.level, LogLevel.error);
      expect(sink.entries.single.message, 'failed token=***');
      expect(sink.entries.single.scope, 'core');
    });

    test('LogManager memoiza loggers por escopo e pode ser resetado', () {
      final sink = MemoryLogSink();
      LogManager.configure(sink: sink);

      expect(
        identical(LogManager.scope('core'), LogManager.scope('core')),
        isTrue,
      );
      LogManager.root.info('started');
      expect(sink.entries.single.scope, 'root');

      LogManager.configure();
      expect(() => LogManager.root.info('no-op'), returnsNormally);
    });
  });
}

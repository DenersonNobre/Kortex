import 'dart:io';

import 'package:kortex_core/kortex_core.dart';
import 'package:test/test.dart';

void main() {
  group('LogCorrelation', () {
    test('propaga traceId dentro de runZoned e limpa fora', () {
      expect(LogCorrelation.current, isNull);
      final inside = LogCorrelation.run('req-123', () => LogCorrelation.current);
      expect(inside, 'req-123');
      expect(LogCorrelation.current, isNull);
    });
  });

  group('FileLogSink', () {
    test('grava entradas e rotaciona quando excede maxBytes', () {
      final dir = Directory.systemTemp.createTempSync('kortex_log_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/app.log');
      final sink = FileLogSink(file, maxBytes: 40);

      sink.write(LogEntry(level: LogLevel.info, scope: 'A', message: '12345678901234567890'));
      sink.write(LogEntry(level: LogLevel.info, scope: 'B', message: '12345678901234567890'));

      expect(file.existsSync(), isTrue);
      expect(File('${file.path}.1').existsSync(), isTrue);
    });
  });

  group('BufferedLogSink', () {
    test('agrupa em lote ao atingir batchSize e descarrega no flush', () async {
      final batches = <List<LogEntry>>[];
      final sink = BufferedLogSink(
        batchSize: 2,
        onFlush: (entries) async => batches.add(entries),
      );

      sink.write(LogEntry(level: LogLevel.info, scope: 'S', message: 'm1'));
      expect(batches, isEmpty);

      sink.write(LogEntry(level: LogLevel.info, scope: 'S', message: 'm2'));
      await Future<void>.delayed(Duration.zero);
      expect(batches.length, 1);
      expect(batches.first.length, 2);

      sink.write(LogEntry(level: LogLevel.info, scope: 'S', message: 'm3'));
      await sink.flush();
      expect(batches.length, 2);
      expect(batches.last.single.message, 'm3');
    });
  });

  group('AnsiTextLogFormatter', () {
    test('aplica cor ANSI e negrito no nivel', () {
      const formatter = AnsiTextLogFormatter();
      final out = formatter.format(
        LogEntry(level: LogLevel.error, scope: 'API', message: 'falha'),
      );
      expect(out, contains('\x1B[31m'));
      expect(out, contains('\x1B[1m[ERROR]\x1B[22m'));
      expect(out, endsWith('\x1B[0m'));
    });
  });
}

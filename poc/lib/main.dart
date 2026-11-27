/// Entrada do app de visitas tecnicas (POC do pacote `kortex`).
///
/// SRP: iniciar o app; toda a composicao vive em `app/visits_app.dart`.
/// NAO faz: regra de negocio nem composicao de dependencias.
///
/// Dependencias: Flutter + `kortex` (via `visits_app.dart`).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kortex_lib/kortex_lib.dart';

import 'app/visits_app.dart';

const _logFile = String.fromEnvironment('LOG_FILE');

/// Ponto de entrada.
void main() {
  _setupLogging();
  LogManager.scope('App').info('Iniciando POC Kortex');
  runApp(createVisitsApp(seedPreview: true));
}

void _setupLogging() {
  final consoleSink = FormattedLogSink(
    debugPrint,
    formatter: const AnsiTextLogFormatter(),
    threshold: kDebugMode ? LogLevel.debug : LogLevel.info,
  );
  final ILogSink sink = _logFile.isEmpty
      ? consoleSink
      : FunctionLogSink((entry) {
          consoleSink.write(entry);
          FileLogSink(File(_logFile)).write(entry);
        });
  LogManager.configure(
    sink: sink,
    threshold: kDebugMode ? LogLevel.debug : LogLevel.info,
  );

  final logger = LogManager.scope('FlutterError');
  final prevFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    logger.error(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    prevFlutterError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.fatal('Erro nao tratado na plataforma', error: error, stackTrace: stack);
    return false;
  };
}

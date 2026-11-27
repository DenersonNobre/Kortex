import 'dart:async';

/// Propagacao de `traceId` / `correlationId` via `Zone` sem acoplar assinaturas.
abstract final class LogCorrelation {
  static const Object _zoneKey = #kortexTraceId;

  /// Retorna o `traceId` ativo na `Zone` atual, ou `null` se ausente.
  static String? get current => Zone.current[_zoneKey] as String?;

  /// Executa [body] com [traceId] disponivel em toda a arvore assincrona.
  static T run<T>(String traceId, T Function() body) {
    return runZoned(body, zoneValues: {_zoneKey: traceId});
  }
}

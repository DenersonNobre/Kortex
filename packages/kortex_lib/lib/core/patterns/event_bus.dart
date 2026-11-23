// [GoF Observer] (behavioral) centralizado: o [EventBus] entrega eventos a
// todos os assinantes do tipo correspondente, sem que produtor e consumidor
// se conheçam.
//
// Atribuição: **GoF Observer** — *Design Patterns* (Gamma/Helm/Johnson/
// Vlissides, 1994), g23.

import 'dart:async';

/// Barramento de eventos tipado (GoF Observer): [emit] publica um evento de
/// [T] para todos os assinantes; [on] assina e devolve uma
/// [StreamSubscription] cujo [StreamSubscription.cancel] desfaz a assinatura.
/// Broadcast: quem assina não recebe eventos anteriores.
class EventBus {
  final Map<Type, StreamController<dynamic>> _controllers = {};

  /// Fluxo de eventos de [T] (broadcast, sem replay).
  Stream<T> stream<T>() => _controller<T>().stream;

  /// Assina [listener] para eventos de [T]; devolve o token de cancelamento.
  StreamSubscription<T> on<T>(void Function(T event) listener) =>
      stream<T>().listen(listener);

  /// Publica [event] para todos os assinantes de [T].
  void emit<T>(T event) => _controller<T>().add(event);

  /// Encerra todos os canais e descarta assinantes.
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  StreamController<T> _controller<T>() =>
      _controllers.putIfAbsent(T, StreamController<T>.broadcast)
          as StreamController<T>;
}

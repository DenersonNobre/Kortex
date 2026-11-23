// Debounce de chamadas com payload: adia a execução de [callback] até que
// [duration] transcorra sem novas chamadas ([call] reseta o timer — só a
// última payload persiste); [cancel] descarta a execução pendente.
//
// Atribuição: **idioma de UI/eventos (tooling)** — fora dos 23 GoF.

import 'dart:async';

/// Adia a execução de [callback] até que [duration] transcorra sem novas
/// chamadas; [call] dentro da janela reseta o timer e substitui a payload
/// pendente (só a última persiste). [cancel] descarta a execução pendente.
class Debouncer<T> {
  Debouncer({required this.duration, required this.callback});

  final Duration duration;

  /// Recebido pela última payload persistida ao fim da janela.
  final void Function(T payload) callback;

  Timer? _timer;

  /// Agenda (ou re-agenda) a execução de [callback] com [payload] na janela.
  void call(T payload) {
    _timer?.cancel();
    _timer = Timer(duration, () => _run(payload));
  }

  /// Cancela a execução pendente; [callback] não será chamado.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _run(T payload) {
    _timer = null;
    callback(payload);
  }
}

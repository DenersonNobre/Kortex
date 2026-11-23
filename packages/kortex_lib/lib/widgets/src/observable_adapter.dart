// Adaptador de reatividade: expõe um [Observable] do `core` como
// [ValueListenable] do Flutter, para que os widgets deste módulo
// ([AsyncButton], [NotifierBuilder], [BusyOverlay]) possam observar padrões
// agnósticos via [NotifierBuilder] (builder canônico de escuta).
//
// SRP: apenas traduz o contrato de observabilidade. NÃO guarda estado próprio —
// o valor e os assinantes permanecem no [Observable] de origem, que segue
// responsável pelo ciclo de vida.
//
// Dependências: [Observable] (core) e [ValueListenable] (Flutter).

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart' show BuildContext, Widget;
import 'package:kortex_lib/core/core.dart' show Observable, ObservableToken;

import 'reactive.dart' show NotifierBuilder;

/// Publica um [Observable] do `core` como [ValueListenable] do Flutter.
///
/// O `ValueListenable` do Flutter assina com `void Function()`, enquanto o
/// [Observable] do core assina com `void Function(T value)` — o adapter guarda
/// um [ObservableToken] por assinatura para preservar o cancelamento, em vez de
/// depender da identidade da closure.
class ObservableAdapter<T> implements ValueListenable<T> {
  ObservableAdapter(this.observable);

  final Observable<T> observable;

  final Map<void Function(), ObservableToken<T>> _tokens = {};

  @override
  T get value => observable.value;

  @override
  void addListener(void Function() listener) {
    if (_tokens.containsKey(listener)) {
      return;
    }
    _tokens[listener] = observable.on((_) => listener());
  }

  @override
  void removeListener(void Function() listener) {
    _tokens.remove(listener)?.cancel();
  }
}

/// Ergonomias de adaptação e observação de [Observable] na UI Flutter.
extension ObservableAdapterExtension<T> on Observable<T> {
  /// Envolve este [Observable] em um [ValueListenable] do Flutter.
  ///
  /// Ex.: `command.isExecuting.asListenable()`.
  ValueListenable<T> asListenable() => ObservableAdapter<T>(this);

  /// Observa reativamente este [Observable] e reconstrói o widget quando o valor
  /// sofrer mutação.
  ///
  /// Ex.: `observable.watch((context, value) => ...)`.
  Widget watch(Widget Function(BuildContext context, T value) builder) {
    return NotifierBuilder<T>(
      listenable: ObservableAdapter<T>(this),
      builder: builder,
    );
  }
}

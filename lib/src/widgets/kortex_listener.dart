/// Efeitos colaterais seguros na UI (`KortexListener`).
///
/// SRP: separar leitura pura (`watch`, descoberta em `initState`) do efeito
/// imperativo (`listener`, sempre fora da fase de `build`). NÃO faz:
/// reconstruir UI (papel do `KortexWatch`) nem guardar valor.
///
/// Patterns: Observer com coleta inicial + guarda de fase do `Scheduler`.
/// Dependências: Flutter (`widgets`, `scheduler`) + camada reativa.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';

/// Ouve mudanças e executa o efeito com `BuildContext` real.
typedef KortexContextListener<T> = void Function(BuildContext context, T value);

/// Executa [listener] quando `watch()` mudar (nunca durante `build`).
class KortexListener<T> extends StatefulWidget {
  /// Cria o ouvinte com leitura pura [watch] e efeito [listener].
  const KortexListener({
    super.key,
    required this.watch,
    required this.listener,
    this.equals,
    this.fireImmediately = false,
    required this.child,
  });

  /// Leitura pura avaliada em `initState` para descobrir dependências.
  final T Function() watch;

  /// Efeito executado fora do `build` quando `watch()` mudar.
  final KortexContextListener<T> listener;

  /// Igualdade da mudança (padrão `==`).
  final KortexEquals<T>? equals;

  /// Dispara [listener] logo após a montagem com o valor inicial.
  final bool fireImmediately;

  /// Subárvore que nunca reconstrói por este widget.
  final Widget child;

  @override
  State<KortexListener<T>> createState() => _KortexListenerState<T>();
}

class _KortexListenerState<T> extends State<KortexListener<T>>
    implements IKortexObserver {
  final Set<IKortexReactiveNode> _deps = {};
  late T _current;
  var _collecting = false;

  @override
  void initState() {
    super.initState();
    _collecting = true;
    try {
      _current = KortexTracker.runWithObserver(this, widget.watch);
    } finally {
      _collecting = false;
    }
    if (widget.fireImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fire(_current));
    }
  }

  @override
  void onRead(IKortexReactiveNode node) {
    if (_collecting) {
      _deps.add(node);
      return;
    }
    _evaluate();
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _evaluate() {
    _unsubscribeAll();
    _collecting = true;
    late T next;
    try {
      next = KortexTracker.runWithObserver(this, widget.watch);
    } finally {
      _collecting = false;
    }
    if (_equal(_current, next)) {
      return;
    }
    _current = next;
    _fire(next);
  }

  bool _equal(T previous, T next) {
    final equals = widget.equals;
    if (equals != null) {
      return equals(previous, next);
    }
    return previous == next;
  }

  void _fire(T value) {
    if (!mounted) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _fire(value));
      return;
    }
    widget.listener(context, value);
  }

  void _unsubscribeAll() {
    for (final dep in List.of(_deps)) {
      dep.removeObserver(this);
    }
    _deps.clear();
  }
}

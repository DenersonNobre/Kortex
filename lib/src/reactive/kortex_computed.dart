/// Valor derivado preguiçoso com cache (`KortexComputed`).
///
/// SRP: derivar um valor de outros nós, recomputando só quando lido após
/// mudança (lazy + cache) e notificando a jusante só se o derivado mudar.
/// NÃO faz: efeitos colaterais (papel do `KortexEffect`) nem loteamento.
///
/// Patterns: Lazy Evaluation + Cache com invalidação em cascata.
/// Dependências: apenas `dart:core` + camada reativa (puro).
library;

import 'kortex_observer.dart';
import 'kortex_signal.dart';

/// Valor computado a partir de [compute], com cache e invalidação lazy.
class KortexComputed<T> implements IKortexReadonlySignal<T>, IKortexObserver {
  /// Cria o derivado com [compute] e [equals] opcional (padrão `==`).
  KortexComputed(T Function() compute, {KortexEquals<T>? equals})
    : _compute = compute,
      _equals = equals ?? _plainEquals;

  static const _disposedMessage = 'KortexComputed usado após dispose()';

  final T Function() _compute;
  final KortexEquals<T> _equals;
  final Set<IKortexObserver> _observers = {};
  final Set<IKortexReactiveNode> _deps = {};
  T? _cached;
  var _hasValue = false;
  var _isDirty = true;
  var _isCollecting = false;
  var _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  T get value {
    _requireAlive();
    _ensureFresh();
    KortexTracker.recordRead(this);
    return _cached as T;
  }

  @override
  T peek() {
    _requireAlive();
    _ensureFresh();
    return _cached as T;
  }

  @override
  void onRead(IKortexReactiveNode node) {
    if (_isDisposed) return;
    if (_isCollecting) {
      _deps.add(node);
      return;
    }
    _invalidate();
  }

  @override
  void addObserver(IKortexObserver observer) {
    _observers.add(observer);
  }

  @override
  void removeObserver(IKortexObserver observer) {
    _observers.remove(observer);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _unsubscribeAll();
    _observers.clear();
  }

  void _ensureFresh() {
    if (!_isDirty && _hasValue) return;
    _recompute();
  }

  void _recompute() {
    _unsubscribeAll();
    final next = _collect();
    _isDirty = false;
    if (!_hasValue) {
      _storeFirst(next);
      return;
    }
    _storeIfChanged(next);
  }

  T _collect() {
    _isCollecting = true;
    try {
      return KortexTracker.runWithObserver(this, _compute);
    } finally {
      _isCollecting = false;
    }
  }

  void _storeFirst(T next) {
    _cached = next;
    _hasValue = true;
  }

  void _storeIfChanged(T next) {
    final previous = _cached as T;
    if (_equals(previous, next)) return;
    _cached = next;
    KortexTracker.notifyChange(this, _observers);
  }

  /// Sem observadores: só marca dirty (recomputa preguiçoso na leitura).
  /// Com observadores: recomputa já e avisa a jusante só se mudou.
  void _invalidate() {
    if (_observers.isEmpty) {
      _isDirty = true;
      return;
    }
    _recompute();
  }

  void _unsubscribeAll() {
    for (final dep in List.of(_deps)) {
      dep.removeObserver(this);
    }
    _deps.clear();
  }

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

bool _plainEquals<T>(T previous, T next) => previous == next;

/// Atalho ergonômico para `KortexComputed(...)`.
KortexComputed<T> kortexComputed<T>(
  T Function() compute, {
  KortexEquals<T>? equals,
}) => KortexComputed(compute, equals: equals);

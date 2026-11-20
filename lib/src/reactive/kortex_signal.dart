/// Sinal mutável com igualdade configurável (`KortexSignal`).
///
/// SRP: guardar um valor, comparar com `equals` e notificar assinantes só
/// quando mudar. NÃO faz: derivação (papel do `KortexComputed`), efeitos
/// (papel do `KortexEffect`) nem loteamento (papel do `KortexTracker`).
///
/// Patterns: Observer (via `IKortexReactiveNode`) + Guard Clause.
/// Dependências: apenas `dart:core` + `kortex_observer.dart` (puro).
library;

import 'kortex_observer.dart';

/// Igualdade entre valor anterior e próximo (`true` = sem mudança).
typedef KortexEquals<T> = bool Function(T previous, T next);

/// Deriva o próximo valor a partir do atual (usado em `update`).
typedef KortexUpdater<T> = T Function(T current);

bool _defaultEquals<T>(T previous, T next) => previous == next;

/// Visão somente-leitura de um sinal (fronteira de encapsulamento).
abstract interface class IKortexReadonlySignal<T>
    implements IKortexReactiveNode {
  /// Indica se o sinal foi descartado.
  bool get isDisposed;

  /// Valor atual, registrando leitura no `KortexTracker` ativo.
  T get value;

  /// Valor atual sem registrar leitura.
  T peek();
}

/// Contêiner mutável com notificação condicional e bloqueio pós-dispose.
class KortexSignal<T> implements IKortexReadonlySignal<T> {
  /// Cria o sinal com [initialValue] e [equals] opcional (padrão `==`).
  KortexSignal(T initialValue, {KortexEquals<T>? equals})
    : _value = initialValue,
      _equals = equals ?? _defaultEquals;

  static const _disposedMessage = 'KortexSignal usado após dispose()';

  T _value;
  final KortexEquals<T> _equals;
  final Set<IKortexObserver> _observers = {};
  var _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  T get value {
    _requireAlive();
    KortexTracker.recordRead(this);
    return _value;
  }

  @override
  T peek() {
    _requireAlive();
    return _value;
  }

  /// Substitui o valor; sem notificação se [equals] aprovar.
  set value(T next) {
    _requireAlive();
    if (_equals(_value, next)) return;
    _value = next;
    KortexTracker.notifyChange(this, _observers);
  }

  /// Aplica [updater] ao valor atual em escrita única.
  void update(KortexUpdater<T> updater) => value = updater(peek());

  /// Visão somente-leitura deste sinal (mesmo ciclo de vida).
  IKortexReadonlySignal<T> get readonly => this;

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
    _observers.clear();
  }

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Atalho ergonômico para `KortexSignal(...)`.
KortexSignal<T> kortexSignal<T>(T initialValue, {KortexEquals<T>? equals}) =>
    KortexSignal(initialValue, equals: equals);

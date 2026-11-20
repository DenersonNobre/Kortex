/// Immutable dependency provider (`KortexProvider` + scope reader).
///
/// SRP: describe HOW to create/dispose a `T` (factory, optional disposal,
/// `lazy` or an external value). It does NOT store instances, resolve the
/// tree nor notify widgets (that is `KortexScope`'s job).
///
/// Patterns: Factory Method (through `create`) + explicit dispose.
/// Dependencies: `dart:core` + `IKortexDisposable` (pure, no Flutter).
///
/// Parameter names follow the SPEC contract and differ from the internal
/// fields — hence this file does not use initializing formals.
// ignore_for_file: prefer_initializing_formals
library;

import '../reactive/reactive.dart';

/// Explicit reader used to resolve siblings inside `KortexProvider.create`.
abstract interface class IKortexScopeReader {
  /// Resolves [T] among the scope's siblings or in the ancestors.
  T read<T>();
}

/// Factory creating [T] receiving only the scope reader.
typedef KortexCreate<T> = T Function(IKortexScopeReader scope);

/// Explicit disposal of an instance created by the provider.
typedef KortexDispose<T> = void Function(T instance);

/// Immutable definition of creation (`create`), `lazy`, `.value` and `dispose`.
class KortexProvider<T> {
  /// Provider with on-demand creation; `dispose` is optional and explicit.
  KortexProvider({
    required KortexCreate<T> create,
    KortexDispose<T>? dispose,
    bool lazy = false,
  }) : _create = create,
       _dispose = dispose,
       isLazy = lazy,
       _value = null,
       isValue = false;

  /// Provider of an external value: no creation and no disposal by the scope.
  KortexProvider.value({required T value})
    : _create = _noFactory,
      _dispose = null,
      isLazy = false,
      _value = value,
      isValue = true;

  static const _valueHasNoFactory =
      'KortexProvider.value does not create instances.';

  static Never _noFactory(IKortexScopeReader _) =>
      throw StateError(_valueHasNoFactory);

  final KortexCreate<T> _create;
  final KortexDispose<T>? _dispose;

  /// True when creation happens on the first `read` only.
  final bool isLazy;

  /// True for `KortexProvider.value` (externally owned).
  final bool isValue;
  final T? _value;

  /// Type token used as key inside the `KortexScope`.
  Type get type => T;

  /// External value (valid for `.value` only).
  T get value => _value as T;

  /// Creates the instance through `create` (`.value` throws via sentinel).
  T createInstance(IKortexScopeReader reader) => _create(reader);

  /// Disposes [instance]: explicit callback or `IKortexDisposable`.
  ///
  /// `.value` instances are never disposed by the scope.
  void disposeInstance(T instance) {
    if (isValue) {
      return;
    }
    final dispose = _dispose;
    if (dispose != null) {
      dispose(instance);
      return;
    }
    if (instance is IKortexDisposable) {
      instance.dispose();
    }
  }
}

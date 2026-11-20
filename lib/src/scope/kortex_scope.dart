/// Dependency scope bound to the widget tree (`KortexScope`).
///
/// SRP: materialize `KortexProvider`s (eager/`lazy`/`.value`), resolve among
/// siblings and ancestors with cycle detection, and dispose in LIFO order on
/// unmount or when providers change. It does NOT do signal reactivity, UI or
/// routing.
///
/// Patterns: Scoped Service Locator (always through `BuildContext`) +
/// versioned `InheritedWidget` for `watch` + deterministic LIFO disposal.
/// Dependencies: `package:flutter/widgets.dart` + internal layers.
library;

import 'package:flutter/widgets.dart';

import 'kortex_provider.dart';

/// Scope providing dependencies to the subtree.
///
/// Resolution (`read`/`watch`) always goes through `BuildContext`, never
/// globally. Instances survive parent rebuilds while the provider objects
/// are the same; replacing them disposes everything and recreates it.
class KortexScope extends StatefulWidget {
  /// Creates the scope with [providers], [overrides] and the subtree [child].
  ///
  /// [overrides] replace providers of the same `Type` (fakes in tests).
  const KortexScope({
    super.key,
    required this.providers,
    this.overrides = const [],
    required this.child,
  });

  /// Creation definitions (order preserved; siblings resolve each other).
  final List<KortexProvider<dynamic>> providers;

  /// Replacements by `Type` (they take precedence over [providers]).
  final List<KortexProvider<dynamic>> overrides;

  /// Subtree with access to the instances.
  final Widget child;

  /// Resolves [T] in the closest ancestor scope that owns it.
  ///
  /// With `listen: true`, rebuilds the caller whenever any ancestor scope
  /// updates its providers.
  static T resolveKortexDependency<T>(
    BuildContext context, {
    required bool listen,
  }) {
    final state = context.findAncestorStateOfType<_KortexScopeState>();
    if (state == null) {
      throw StateError(_noScopeMessage<T>());
    }
    final instance = state._resolve<T>();
    if (listen) {
      state._dependOnScopes(context);
    }
    return instance;
  }

  static String _noScopeMessage<T>() =>
      'KortexScope: no ancestor KortexScope to resolve $T. '
      'Wrap the subtree in a KortexScope with KortexProvider<$T>.';

  /// Captures the instances visible above [context] for an `Overlay`.
  ///
  /// Used in `showDialog`/`showModalBottomSheet`: builds a `KortexScope` with
  /// `KortexProvider.value` (without transferring `dispose` ownership).
  /// Only already materialized instances are captured.
  static KortexScope capture({
    required BuildContext context,
    required Widget child,
  }) {
    final collected = <Type, Object?>{};
    var state = context.findAncestorStateOfType<_KortexScopeState>();
    while (state != null) {
      for (final entry in state._instances.entries) {
        collected.putIfAbsent(entry.key, () => entry.value);
      }
      state = state._parentScope;
    }
    return KortexScope(
      providers: [
        for (final entry in collected.entries)
          _CapturedProvider(entry.key, entry.value),
      ],
      child: child,
    );
  }

  @override
  State<KortexScope> createState() => _KortexScopeState();
}

/// Reader delegating to the owning scope state.
class _ScopeReader implements IKortexScopeReader {
  _ScopeReader(this._state);

  final _KortexScopeState _state;

  @override
  T read<T>() => _state._resolve<T>();
}

/// Versioned marker: `watch` rebuilds when the number changes.
class _KortexInherited extends InheritedWidget {
  const _KortexInherited({required this.version, required super.child});

  final int version;

  @override
  bool updateShouldNotify(_KortexInherited oldWidget) =>
      version != oldWidget.version;
}

/// Captured value provider with an explicit type token.
///
/// `KortexProvider<dynamic>.value` would lose the `Type` (becoming
/// `dynamic`) and never match on resolution — here the token travels with
/// the value.
class _CapturedProvider extends KortexProvider<dynamic> {
  _CapturedProvider(Type type, Object? value)
    : _type = type,
      super.value(value: value);

  final Type _type;

  @override
  Type get type => _type;
}

class _KortexScopeState extends State<KortexScope> {
  final Map<Type, Object?> _instances = {};
  final List<Type> _creationOrder = [];
  final List<Type> _resolving = [];
  late Map<Type, KortexProvider<dynamic>> _effective;
  late final _ScopeReader _reader;
  var _version = 0;

  @override
  void initState() {
    super.initState();
    _reader = _ScopeReader(this);
    _rebuildEffective();
    _initEager();
  }

  @override
  void didUpdateWidget(KortexScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameProviders(oldWidget)) {
      return;
    }
    _disposeAll();
    _rebuildEffective();
    _initEager();
    _version++;
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _KortexInherited(version: _version, child: widget.child);

  T _resolve<T>() {
    final provider = _effective[T];
    if (provider != null) {
      return _materialize<T>(provider);
    }
    final parent = _parentScope;
    if (parent != null) {
      return parent._resolve<T>();
    }
    throw StateError(_missingProviderMessage<T>());
  }

  void _dependOnScopes(BuildContext context) {
    context.visitAncestorElements((element) {
      if (element is InheritedElement && element.widget is _KortexInherited) {
        context.dependOnInheritedElement(element);
      }
      return true;
    });
  }

  _KortexScopeState? get _parentScope =>
      context.findAncestorStateOfType<_KortexScopeState>();

  void _rebuildEffective() {
    final effective = <Type, KortexProvider<dynamic>>{};
    for (final provider in widget.providers) {
      effective[provider.type] = provider;
    }
    for (final override in widget.overrides) {
      effective[override.type] = override;
    }
    _effective = effective;
  }

  void _initEager() {
    for (final type in _effective.keys) {
      _materializeDynamic(type);
    }
  }

  bool _sameProviders(KortexScope oldWidget) {
    if (!_sameList(widget.providers, oldWidget.providers)) {
      return false;
    }
    return _sameList(widget.overrides, oldWidget.overrides);
  }

  bool _sameList(
    List<KortexProvider<dynamic>> current,
    List<KortexProvider<dynamic>> previous,
  ) {
    if (identical(current, previous)) {
      return true;
    }
    if (current.length != previous.length) {
      return false;
    }
    for (var i = 0; i < current.length; i++) {
      if (!identical(current[i], previous[i])) {
        return false;
      }
    }
    return true;
  }

  void _materializeDynamic(Type type) {
    final provider = _effective[type];
    if (provider == null || provider.isLazy) {
      return;
    }
    if (_instances.containsKey(type)) {
      return;
    }
    if (provider.isValue) {
      _instances[type] = provider.value;
      _creationOrder.add(type);
      return;
    }
    _createDynamic(type, provider);
  }

  T _materialize<T>(KortexProvider<dynamic> provider) {
    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }
    if (provider.isValue) {
      return _storeValue<T>(provider);
    }
    return _createDynamic(T, provider) as T;
  }

  Object? _createDynamic(Type type, KortexProvider<dynamic> provider) {
    if (_resolving.contains(type)) {
      throw StateError(_cycleMessage(type));
    }
    _resolving.add(type);
    try {
      final instance = provider.createInstance(_reader);
      _instances[type] = instance;
      _creationOrder.add(type);
      return instance;
    } finally {
      _resolving.remove(type);
    }
  }

  T _storeValue<T>(KortexProvider<dynamic> provider) {
    final value = provider.value as T;
    _instances[T] = value;
    _creationOrder.add(T);
    return value;
  }

  void _disposeAll() {
    for (var i = _creationOrder.length - 1; i >= 0; i--) {
      _disposeInstance(_creationOrder[i]);
    }
    _creationOrder.clear();
    _instances.clear();
  }

  void _disposeInstance(Type type) {
    final provider = _effective[type];
    if (provider == null) {
      return;
    }
    provider.disposeInstance(_instances[type]);
  }

  String _missingProviderMessage<T>() =>
      'KortexScope: no KortexProvider<$T> found in the tree. '
      'Register it in an ancestor KortexScope.';

  String _cycleMessage(Type type) =>
      'KortexScope: circular dependency detected: '
      '${[..._resolving, type].join(' -> ')}.';
}

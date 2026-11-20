/// Escopo de dependências atrelado à árvore de widgets (`KortexScope`).
///
/// SRP: materializar `KortexProvider`s (eager/`lazy`/`.value`), resolver
/// entre irmãos e ancestrais com detecção de ciclo, e descartar em LIFO ao
/// desmontar ou trocar providers. NÃO faz: reatividade de sinais, UI ou
/// roteamento.
///
/// Patterns: Service Locator escopado (sempre via `BuildContext`) +
/// `InheritedWidget` versionado para `watch` + LIFO determinístico.
/// Dependências: `package:flutter/widgets.dart` + camadas internas.
library;

import 'package:flutter/widgets.dart';

import 'kortex_provider.dart';

/// Escopo que provisiona dependências para a subárvore.
///
/// Resolução (`read`/`watch`) sempre via `BuildContext`, nunca global.
/// Instâncias sobrevivem a rebuilds do pai enquanto os objetos provider
/// forem os mesmos; trocá-los descarta tudo e recria do zero.
class KortexScope extends StatefulWidget {
  /// Cria o escopo com [providers] e a subárvore [child].
  const KortexScope({super.key, required this.providers, required this.child});

  /// Definições de criação (ordem preservada; irmãos resolvem entre si).
  final List<KortexProvider<dynamic>> providers;

  /// Subárvore com acesso às instâncias.
  final Widget child;

  /// Resolve [T] no escopo ancestral mais próximo que o possuir.
  ///
  /// Com `listen: true`, reconstrói o chamador quando qualquer escopo
  /// ancestral atualizar seus providers.
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
      'KortexScope: nenhum KortexScope ancestral para resolver $T. '
      'Envolva a subárvore num KortexScope com KortexProvider<$T>.';

  @override
  State<KortexScope> createState() => _KortexScopeState();
}

/// Leitor que delega ao estado do escopo dono.
class _ScopeReader implements IKortexScopeReader {
  _ScopeReader(this._state);

  final _KortexScopeState _state;

  @override
  T read<T>() => _state._resolve<T>();
}

/// Marcador versionado: `watch` reconstrói quando o número muda.
class _KortexInherited extends InheritedWidget {
  const _KortexInherited({required this.version, required super.child});

  final int version;

  @override
  bool updateShouldNotify(_KortexInherited oldWidget) =>
      version != oldWidget.version;
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
      return _materialize<T>(provider as KortexProvider<T>);
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
    _effective = effective;
  }

  void _initEager() {
    for (final type in _effective.keys) {
      _materializeDynamic(type);
    }
  }

  bool _sameProviders(KortexScope oldWidget) {
    final current = widget.providers;
    final previous = oldWidget.providers;
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

  T _materialize<T>(KortexProvider<T> provider) {
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

  T _storeValue<T>(KortexProvider<T> provider) {
    final value = provider.value;
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
      'KortexScope: nenhum KortexProvider<$T> encontrado na árvore. '
      'Registre-o num KortexScope ancestral.';

  String _cycleMessage(Type type) =>
      'KortexScope: dependência circular detectada: '
      '${[..._resolving, type].join(' -> ')}.';
}

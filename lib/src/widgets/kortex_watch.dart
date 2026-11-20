/// Reconstrução granular com `child` estático (`KortexWatch`).
///
/// SRP: rebuildar só este trecho quando sinais lidos mudarem, preservando
/// o [child] imutável. NÃO faz: filtrar por igualdade (papel do
/// `KortexSelector`) nem efeitos colaterais (papel do `KortexListener`).
///
/// Patterns: Observer com coleta em `build` + `setState` fora de fase.
/// Dependências: Flutter (`widgets`, `scheduler`) + camada reativa.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';

/// Constrói UI reativa com `child` opcional preservado entre rebuilds.
typedef KortexWatchBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

/// Trecho que reconstrói quando qualquer sinal lido em [builder] mudar.
class KortexWatch extends StatefulWidget {
  /// Cria o trecho observável com [builder] e [child] estático opcional.
  const KortexWatch({super.key, required this.builder, this.child});

  /// Leitura rastreada; `child` repassado intacto a cada rebuild.
  final KortexWatchBuilder builder;

  /// Subárvore imutável preservada entre reconstruções.
  final Widget? child;

  @override
  State<KortexWatch> createState() => _KortexWatchState();
}

class _KortexWatchState extends State<KortexWatch> implements IKortexObserver {
  final Set<IKortexReactiveNode> _deps = {};
  var _collecting = false;

  @override
  void onRead(IKortexReactiveNode node) {
    if (_collecting) {
      _deps.add(node);
      return;
    }
    _schedule();
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _unsubscribeAll();
    _collecting = true;
    try {
      return KortexTracker.runWithObserver(
        this,
        () => widget.builder(context, widget.child),
      );
    } finally {
      _collecting = false;
    }
  }

  void _schedule() {
    if (!mounted) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _rebuild());
      return;
    }
    _rebuild();
  }

  void _rebuild() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _unsubscribeAll() {
    for (final dep in List.of(_deps)) {
      dep.removeObserver(this);
    }
    _deps.clear();
  }
}

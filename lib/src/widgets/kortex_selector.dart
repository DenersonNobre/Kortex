/// Reconstrução filtrada por igualdade (`KortexSelector`).
///
/// SRP: rebuildar só quando o valor de [selector] mudar segundo [equals],
/// delegando a observação a um `KortexComputed` + `KortexWatch` interno.
/// NÃO faz: efeitos colaterais nem leitura não rastreada.
///
/// Patterns: Composite (derivado observável + trecho observável).
/// Dependências: Flutter + camadas `reactive` (sem estado global).
library;

import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';
import 'kortex_watch.dart';

/// Constrói UI a partir da seleção, rebuildando só quando ela mudar.
typedef KortexSelectorBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  Widget? child,
);

/// Trecho que observa `selector()` e reconstrói apenas em mudança real.
class KortexSelector<T> extends StatefulWidget {
  /// Cria o seletor com [selector], [builder], [equals] e [child].
  const KortexSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.equals,
    this.child,
  });

  /// Extrai o valor observado (lido de forma rastreada).
  final T Function() selector;

  /// Constrói a UI com o valor selecionado e o [child] intacto.
  final KortexSelectorBuilder<T> builder;

  /// Igualdade da seleção (padrão `==`).
  final KortexEquals<T>? equals;

  /// Subárvore imutável repassada intacta a cada rebuild.
  final Widget? child;

  @override
  State<KortexSelector<T>> createState() => _KortexSelectorState<T>();
}

class _KortexSelectorState<T> extends State<KortexSelector<T>> {
  late KortexComputed<T> _computed;

  @override
  void initState() {
    super.initState();
    _computed = _createComputed();
  }

  @override
  void didUpdateWidget(KortexSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _computed.dispose();
    _computed = _createComputed();
  }

  @override
  void dispose() {
    _computed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KortexWatch(
    builder: (context, _) =>
        widget.builder(context, _computed.value, widget.child),
  );

  KortexComputed<T> _createComputed() =>
      KortexComputed<T>(widget.selector, equals: widget.equals);
}

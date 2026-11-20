/// Página `StatelessWidget` com controller resolvido via escopo.
///
/// SRP: resolver `TController` no `KortexScope` e delegar a `buildPage`.
/// NÃO faz: gerenciar estado (papel dos sinais), navegação ou provisão.
///
/// Patterns: Template Method (`build` chama `buildPage`).
/// Dependências: Flutter + camadas `reactive`/`scope` (sem GetView global).
library;

import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';
import '../scope/scope.dart';

/// Página sem estado cujo controller vem do `KortexScope` ancestral.
abstract class IKortexPage<TController extends IKortexController>
    extends StatelessWidget {
  /// Cria a página (sem `StatefulWidget` para estado de negócio).
  const IKortexPage({super.key});

  /// Resolve o controller via `BuildContext` (falha sem escopo).
  TController controllerOf(BuildContext context) =>
      context.readKortex<TController>();

  /// Constrói a UI com o [controller] resolvido.
  Widget buildPage(BuildContext context, TController controller);

  @override
  Widget build(BuildContext context) =>
      buildPage(context, controllerOf(context));
}

// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';

/// Escopo hierárquico na árvore de widgets que provê um presenter tipado [T]
/// para todos os seus descendentes através do mecanismo canônico de [InheritedWidget].
@Deprecated(
  'Use KortexScope with IKortexController from package:kortex/kortex.dart instead.',
)
class PresenterScope<T extends Object> extends InheritedWidget {
  const PresenterScope({
    super.key,
    required this.presenter,
    required super.child,
  });

  final T presenter;

  /// Obtém o presenter mais próximo do tipo [T] no contexto da árvore de widgets.
  /// Lança [StateError] amigável caso nenhum [PresenterScope<T>] seja encontrado acima.
  static T of<T extends Object>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PresenterScope<T>>();
    if (scope == null) {
      throw StateError(
        'Nenhum PresenterScope<$T> foi encontrado na árvore de widgets acima de $context. '
        'Certifique-se de envolver seus widgets no PresenterScope(presenter: ..., child: ...).',
      );
    }
    return scope.presenter;
  }

  @override
  bool updateShouldNotify(covariant PresenterScope<T> oldWidget) {
    return presenter != oldWidget.presenter;
  }
}

/// Extensão de conveniência em [BuildContext] para leitura fluente do presenter.
@Deprecated(
  'Use KortexScope with IKortexController from package:kortex/kortex.dart instead.',
)
extension PresenterContextExtension on BuildContext {
  /// Localiza o presenter [T] no [PresenterScope] ascendente mais próximo.
  T presenter<T extends Object>() => PresenterScope.of<T>(this);
}

/// Widget base abstrato (estilo View declarativa com DI contextual)
/// que injeta automaticamente a instância de [T] resolvida pelo [PresenterScope].
///
/// **Regra arquitetural**: Esta classe é estritamente [abstract] e só pode ser
/// herdada por componentes visuais concretos, nunca instanciada diretamente.
/// Permite acessar [presenter] como getter direto em qualquer método da classe
/// implementando [build], ou recebê-lo via [buildWithPresenter].
@Deprecated(
  'Use KortexScope with IKortexController from package:kortex/kortex.dart instead.',
)
abstract class PresenterView<T extends Object> extends StatelessWidget {
  const PresenterView({super.key});

  /// Referência contextual fraca gerenciada exclusivamente pelo [PresenterViewElement].
  static final Expando<BuildContext> _elementContexts = Expando<BuildContext>(
    'PresenterViewElements',
  );

  /// Getter tipado que resolve o presenter [T] no escopo da árvore.
  /// Pode ser acessado tanto dentro do método de build quanto em métodos
  /// auxiliares de evento da classe.
  @protected
  T get presenter {
    final context = _elementContexts[this];
    if (context == null) {
      throw StateError(
        'Não é possível acessar o getter "presenter" antes da montagem da view na árvore '
        'de widgets ou após seu descarte.',
      );
    }
    return PresenterScope.of<T>(context);
  }

  /// Constrói o widget recebendo o [BuildContext] e a instância de [presenter].
  /// Por padrão, delega para [build(context)] caso a subclasse tenha sobrescrito apenas o [build].
  Widget buildWithPresenter(BuildContext context, T presenter) {
    return build(context);
  }

  @override
  @protected
  Widget build(BuildContext context) {
    return buildWithPresenter(context, PresenterScope.of<T>(context));
  }

  @override
  StatelessElement createElement() => PresenterViewElement<T>(this);
}

/// Elemento especializado que amarra o [BuildContext] vivo à instância do [PresenterView]
/// durante seu ciclo na árvore, mantendo a classe do widget 100% imutável.
class PresenterViewElement<T extends Object> extends StatelessElement {
  PresenterViewElement(PresenterView<T> super.widget);

  @override
  Widget build() {
    PresenterView._elementContexts[widget] = this;
    return super.build();
  }

  @override
  void unmount() {
    PresenterView._elementContexts[widget] = null;
    super.unmount();
  }
}

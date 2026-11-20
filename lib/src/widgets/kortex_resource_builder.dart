/// Renderização exaustiva de `IKortexAsyncState` (`KortexResourceBuilder`).
///
/// SRP: mapear `Loading`/`Data`/`Error` para widgets via `switch` do Dart 3,
/// observando o `resource` com um `KortexWatch` interno. NÃO faz: carregar
/// dados, retry automático ou guardar estado.
///
/// Patterns: Composite (observação delegada) + Pattern Matching exaustivo.
/// Dependências: Flutter + camadas `reactive` (sem estado global).
library;

import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';
import 'kortex_watch.dart';

/// Constrói o widget de erro com [error] e [stackTrace] opcional.
typedef KortexErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// Constrói o widget de dados com [value].
typedef KortexDataWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

/// Renderiza cada estado de [resource] com o construtor correspondente.
class KortexResourceBuilder<T> extends StatelessWidget {
  /// Cria o construtor com os 3 ramos de `IKortexAsyncState`.
  const KortexResourceBuilder({
    super.key,
    required this.resource,
    required this.loading,
    required this.error,
    required this.data,
  });

  /// Recurso observado (rebuild a cada transição de estado).
  final KortexResource<T> resource;

  /// Ramo de carregamento (`Loading`, com ou sem `previousValue`).
  final WidgetBuilder loading;

  /// Ramo de falha (`Error`).
  final KortexErrorWidgetBuilder error;

  /// Ramo de sucesso (`Data`).
  final KortexDataWidgetBuilder<T> data;

  @override
  Widget build(BuildContext context) => KortexWatch(
    builder: (context, child) {
      final state = resource.state.value;
      return switch (state) {
        KortexAsyncLoading<T>() => loading(context),
        KortexAsyncData<T>(value: final value) => data(context, value),
        KortexAsyncError<T>(error: final failure, stackTrace: final stack) =>
          error(context, failure, stack),
      };
    },
  );
}

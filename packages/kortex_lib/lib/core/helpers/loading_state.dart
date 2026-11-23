/// Representa os possíveis estados de carregamento em fluxos assíncronos e paginação.
enum LoadingState {
  /// Estado inicial antes de qualquer disparo.
  initial,

  /// Carregamento inicial em andamento (ex.: primeira carga ou refresh completo).
  loading,

  /// Conteúdo carregado com sucesso e pronto para interação.
  loaded,

  /// Carregamento incremental em andamento (ex.: próxima página de lista infinita).
  loadingMore,

  /// Ocorreu uma falha no carregamento.
  error;

  /// Indica se o estado atual é o inicial.
  bool get isInitial => this == LoadingState.initial;

  /// Indica se o carregamento principal está em andamento.
  bool get isLoading => this == LoadingState.loading;

  /// Indica se os dados foram carregados com sucesso.
  bool get isLoaded => this == LoadingState.loaded;

  /// Indica se uma carga incremental de próxima página está em andamento.
  bool get isLoadingMore => this == LoadingState.loadingMore;

  /// Indica se o estado atual representa erro.
  bool get isError => this == LoadingState.error;

  /// Indica se qualquer operação assíncrona está ativa (inicial ou incremental).
  bool get isBusy => isLoading || isLoadingMore;

  /// Indica se novas páginas podem ser solicitadas (somente quando [loaded]).
  bool get canLoadMore => this == LoadingState.loaded;
}

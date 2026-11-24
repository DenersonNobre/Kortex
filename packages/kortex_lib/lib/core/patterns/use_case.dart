/// Contrato para casos de uso com entrada [TIn] e saída assíncrona [TOut].
abstract interface class IUseCase<TIn, TOut> {
  /// Executa o caso de uso recebendo [input].
  Future<TOut> call(TIn input);
}

/// Contrato para casos de uso sem parâmetros de entrada.
abstract interface class IUseCaseNoInput<TOut> {
  /// Executa o caso de uso sem argumentos.
  Future<TOut> call();
}

/// `IResult` selado do exemplo (falha esperada sem exceção).
///
/// SRP: representar sucesso (`Ok`) ou falha de negócio (`Fail` com
/// `code` + `message`). NÃO faz: exceções, stack traces nem logging.
///
/// Patterns: Sealed Class + Pattern Matching exaustivo no consumo.
/// Dependências: apenas `dart:core` (puro).
library;

/// Resultado de operação: `Ok(value)` ou `Fail(code, message)`.
sealed class IResult<T> {
  /// Base selada (só `Ok` e `Fail` estendem).
  const IResult();

  /// Verdadeiro quando é `Ok`.
  bool get isSuccess => this is Ok<T>;

  /// Verdadeiro quando é `Fail`.
  bool get isFailure => this is Fail<T>;
}

/// Sucesso com [value].
final class Ok<T> extends IResult<T> {
  /// Cria o sucesso com [value].
  const Ok(this.value);

  /// Valor produzido.
  final T value;
}

/// Falha esperada de negócio com [code] e [message].
final class Fail<T> extends IResult<T> {
  /// Cria a falha com [code] e [message].
  const Fail(this.code, this.message);

  /// Código estável para branching (nunca texto livre).
  final String code;

  /// Mensagem legível para exibição/log.
  final String message;
}

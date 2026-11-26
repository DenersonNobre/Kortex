// [Result monad] puro: representa sucesso ou falha tipada sem exceções para
// o fluxo esperado.
//
// SRP: carrega um dos dois ramos e oferece transformação (map/fold).
// NÃO loga, NÃO serializa com timestamp, NÃO depende de infraestrutura.
//
// Dependências: nenhuma.

/// Resultado selado de uma operação: [Success] ou [Failure].
///
/// O prefixo `I` segue a convenção do dono (abstrações levam `I`;
/// concretas como [Success]/[Failure] não levam).
sealed class IResult<TSuccess, TFailure> {
  const IResult();

  bool get isSuccess => this is Success<TSuccess, TFailure>;
  bool get isFailure => this is Failure<TSuccess, TFailure>;

  /// Consome os dois ramos com callbacks nomeados e exaustivos.
  R fold<R>({
    required R Function(TSuccess value) onSuccess,
    required R Function(TFailure failure) onFailure,
  }) => switch (this) {
    Success(value: final value) => onSuccess(value),
    Failure(value: final failure) => onFailure(failure),
  };

  /// Valor do sucesso ou `null` quando em falha.
  TSuccess? getOrNull() => switch (this) {
    Success(value: final value) => value,
    Failure() => null,
  };

  /// Falha ou `null` quando em sucesso.
  TFailure? getOrNullFailure() => switch (this) {
    Success() => null,
    Failure(value: final failure) => failure,
  };

  /// Transforma o sucesso preservando a falha intacta.
  IResult<R, TFailure> mapSuccess<R>(R Function(TSuccess value) transform) =>
      switch (this) {
        Success(value: final value) => Success(transform(value)),
        Failure(value: final failure) => Failure(failure),
      };

  /// Transforma a falha preservando o sucesso intacto.
  IResult<TSuccess, R> mapFailure<R>(R Function(TFailure failure) transform) =>
      switch (this) {
        Success(value: final value) => Success(value),
        Failure(value: final failure) => Failure(transform(failure)),
      };

  /// Valor do sucesso ou o fallback derivado da falha.
  TSuccess getOrElse(TSuccess Function(TFailure failure) onFailure) =>
      fold(onSuccess: (value) => value, onFailure: onFailure);

  /// Valor do sucesso; lança [StateError] quando em falha.
  TSuccess getOrThrow([String Function(TFailure failure)? message]) => fold(
    onSuccess: (value) => value,
    onFailure: (failure) => throw StateError(
      message == null ? 'IResult em falha' : message(failure),
    ),
  );
}

/// Ramo de sucesso de um [IResult].
final class Success<TSuccess, TFailure> extends IResult<TSuccess, TFailure> {
  const Success(this.value);

  final TSuccess value;
}

/// Ramo de falha de um [IResult].
final class Failure<TSuccess, TFailure> extends IResult<TSuccess, TFailure> {
  const Failure(this.value);

  final TFailure value;
}

/// Base unificada das falhas de domínio (funde `Failure` + `DomainFailure`).
///
/// `TFailure` de [IResult] segue sem constraint — qualquer tipo (`String`,
/// `ValidationError`, `StateTransitionFailure`) continua válido; [IFailure]
/// é a base recomendada quando se quer `code`/`toMap`/hierarquia.
abstract class IFailure implements Exception {
  const IFailure({required this.code, required this.message, this.details});

  final String code;
  final String message;
  final Object? details;

  /// Alias de [details] para leitura de causa em diagnóstico.
  Object? get cause => details;

  /// Mapa determinístico para log/telemetria (sem timestamp no getter —
  /// dois `toMap()` seguidos devolvem o mesmo valor).
  Map<String, Object?> toMap() => {
    'code': code,
    'message': message,
    'details': details?.toString(),
  };

  @override
  String toString() =>
      'IFailure(code: $code, message: $message, details: $details)';
}

/// Extensoes ergonomicas para criacao de [IResult].
extension DnoResultValueExtension<T> on T {
  /// Envelopa o valor em um [Success].
  IResult<T, TFailure> toSuccess<TFailure>() => Success<T, TFailure>(this);
}

extension DnoResultFailureExtension<TFailure> on TFailure {
  /// Envelopa a falha em um [Failure].
  IResult<TSuccess, TFailure> toFailure<TSuccess>() =>
      Failure<TSuccess, TFailure>(this);
}

/// Extensões funcionais e ergonômicas para [IResult].
extension DnoResultExtensions<TSuccess, TFailure>
    on IResult<TSuccess, TFailure> {
  /// Executa o callback [fn] se este resultado for um sucesso.
  IResult<TSuccess, TFailure> onSuccess(void Function(TSuccess data) fn) {
    if (this case Success(value: final data)) {
      fn(data);
    }
    return this;
  }

  /// Executa o callback [fn] se este resultado for uma falha.
  IResult<TSuccess, TFailure> onFailure(void Function(TFailure error) fn) {
    if (this case Failure(value: final error)) {
      fn(error);
    }
    return this;
  }
}

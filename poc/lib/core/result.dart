/// `AppResult` da POC baseado no `IResult` de `kortex_lib`.
///
/// SRP: padronizar falhas de negocio como `AppFailure(code, message)` sem
/// duplicar o pattern `Result` ja fornecido pela biblioteca.
library;

import 'package:kortex_lib/kortex_lib.dart';

export 'package:kortex_lib/kortex_lib.dart' show Failure, IResult, Success;

/// Falha esperada de negocio com [code] e [message].
final class AppFailure {
  /// Cria a falha com [code] e [message].
  const AppFailure(this.code, this.message);

  /// Codigo estavel para branching (nunca texto livre).
  final String code;

  /// Mensagem legivel para exibicao/log.
  final String message;
}

/// Resultado padronizado da POC: `Success<T, AppFailure>` ou
/// `Failure<T, AppFailure>`.
typedef AppResult<T> = IResult<T, AppFailure>;

/// Atalhos ergonomicos para ler [AppFailure.code] e [AppFailure.message]
/// diretamente de `Failure<T, AppFailure>`.
extension AppFailureResultExt<T> on Failure<T, AppFailure> {
  /// Codigo da falha.
  String get code => value.code;

  /// Mensagem da falha.
  String get message => value.message;
}

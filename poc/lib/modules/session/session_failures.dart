/// Codigos de falha da sessao.
///
/// SRP: centralizar os `code`s de `Fail` do modulo de sessao.
library;

/// Codigos de falha de negocio da sessao.
abstract final class SessionFailureCodes {
  /// Nome do usuario vazio.
  static const nameEmpty = 'SESSION_NAME_EMPTY';

  /// Especialidade do usuario vazia.
  static const specialtyEmpty = 'SESSION_SPECIALTY_EMPTY';
}

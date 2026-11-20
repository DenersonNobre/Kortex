/// Codigos estaveis de falha do modulo de clientes.
///
/// SRP: centralizar os `code`s de `Fail` do agregado cliente.
/// NAO faz: mensagens (vao no `Fail.message` de cada sitio).
library;

/// Codigos de falha de negocio dos clientes.
abstract final class ClientFailureCodes {
  /// Nome do cliente vazio.
  static const nameEmpty = 'CLIENT_NAME_EMPTY';

  /// Telefone fora do formato esperado (10 ou 11 digitos).
  static const phoneInvalid = 'CLIENT_PHONE_INVALID';

  /// Id sem cliente correspondente.
  static const notFound = 'CLIENT_NOT_FOUND';
}

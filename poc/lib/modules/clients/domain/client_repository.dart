/// Porta de persistencia do agregado cliente.
///
/// SRP: contrato minimo de leitura/escrita de clientes.
/// NAO faz: validar regras nem escolher tecnologia.
///
/// Patterns: Port explicita (ISP).
/// Dependencias: apenas a entidade (puro).
library;

import 'client.dart';

/// Contrato de persistencia usado pelo modulo de clientes e por `visits`.
abstract interface class ClientRepository {
  /// Lista todos os clientes ordenados por `id`.
  Future<List<Client>> listClients();

  /// Busca por [id] ou `null` quando ausente.
  Future<Client?> findClientById(int id);

  /// Insere (gera `id` quando `0`) ou substitui pelo `id`.
  Future<Client> saveClient(Client client);
}

/// Fachada de casos de uso do modulo de clientes (`ClientUseCases`).
///
/// SRP: agregar listagem, criacao e edicao num contrato injetavel.
/// NAO faz: regra de negocio (vive nos commands) nem I/O.
///
/// Patterns: Facade de UseCases (CQRS sem Mediator).
/// Dependencias: commands + porta (puro).
library;

import '../../../core/result.dart';
import '../commands/.index.dart';
import '../domain/.index.dart';

/// Contrato unico consumido pelo controller de clientes.
abstract interface class ClientUseCases {
  /// Lista clientes; [search] filtra por nome (sem diferenciar caixa).
  Future<List<Client>> listClients({String search});

  /// Cria um cliente.
  Future<Result<Client>> createClient({
    required String name,
    required String phone,
    String address,
  });

  /// Edita um cliente existente.
  Future<Result<Client>> updateClient(
    int id, {
    String? name,
    String? phone,
    String? address,
  });
}

/// Implementacao padrao compondo commands e a porta.
class DefaultClientUseCases implements ClientUseCases {
  /// Monta a fachada sobre o repositorio [clients].
  DefaultClientUseCases({required ClientRepository clients})
    : _clients = clients,
      _create = CreateClientCommand(clients),
      _update = UpdateClientCommand(clients);

  final ClientRepository _clients;
  final CreateClientCommand _create;
  final UpdateClientCommand _update;

  @override
  Future<List<Client>> listClients({String search = ''}) async {
    final all = await _clients.listClients();
    final term = search.trim().toLowerCase();
    if (term.isEmpty) return all;
    return [
      for (final client in all)
        if (client.name.toLowerCase().contains(term)) client,
    ];
  }

  @override
  Future<Result<Client>> createClient({
    required String name,
    required String phone,
    String address = '',
  }) => _create(name: name, phone: phone, address: address);

  @override
  Future<Result<Client>> updateClient(
    int id, {
    String? name,
    String? phone,
    String? address,
  }) => _update(id, name: name, phone: phone, address: address);
}

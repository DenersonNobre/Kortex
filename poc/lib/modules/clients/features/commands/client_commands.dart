/// Commands do agregado cliente (criar e editar).
///
/// SRP: mutacoes de cliente devolvendo `IResult`. NAO faz: leitura para a UI.
///
/// Patterns: Command com guarda de invariante e `IResult`.
/// Dependencias: porta + dominio (puro).
library;

import '../../../../core/result.dart';
import '../../domain/.index.dart';

/// Cria um cliente validado.
class CreateClientCommand {
  /// Cria o command sobre [clients].
  const CreateClientCommand(this._clients);

  final IClientRepository _clients;

  /// Cria e persiste, ou devolve o `Fail` do VO (nada persiste).
  Future<AppResult<Client>> call({
    required String name,
    required String phone,
    String address = '',
  }) async {
    final created = Client.create(name: name, phone: phone, address: address);
    if (created is Failure<Client, AppFailure>) {
      return created;
    }
    return Success(await _clients.saveClient((created as Success<Client, AppFailure>).value));
  }
}

/// Edita nome, telefone ou endereco de um cliente existente.
class UpdateClientCommand {
  /// Cria o command sobre [clients].
  const UpdateClientCommand(this._clients);

  final IClientRepository _clients;

  /// Atualiza os campos informados; campos nulos ficam como estao.
  Future<AppResult<Client>> call(
    int id, {
    String? name,
    String? phone,
    String? address,
  }) async {
    final current = await _clients.findClientById(id);
    if (current == null) {
      return const Failure(AppFailure(ClientFailureCodes.notFound, 'Cliente nao encontrado.'));
    }
    final updated = Client.create(
      name: name ?? current.name,
      phone: phone ?? current.phone,
      address: address ?? current.address,
    );
    if (updated is Failure<Client, AppFailure>) {
      return updated;
    }
    final stored = (updated as Success<Client, AppFailure>).value.copyWith(id: current.id);
    return Success(await _clients.saveClient(stored));
  }
}

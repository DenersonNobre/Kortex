/// Controller reativo da area de clientes.
///
/// SRP: expor a lista de clientes (com busca por nome), carregar e cadastrar,
/// delegando regra ao `IClientUseCases`. NAO faz: UI nem persistencia direta.
///
/// Patterns: `IKortexController` + `KortexResource` (carga) + sinal de busca.
/// Dependencias: `kortex` + camada `features` do modulo de clientes.
library;

import 'package:kortex/kortex.dart';

import '../../../../core/result.dart';
import '../../clients/domain/.index.dart';
import '../../clients/features/.index.dart';

/// Controller da tela de Clientes.
class ClientsController extends IKortexController {
  /// Registra resource e sinais no `disposeBag`.
  ClientsController(this._useCases) {
    clients = autoDispose(
      kortexResource<List<Client>>(() => _load(), immediate: false),
    );
    autoDispose(search);
    autoDispose(error);
  }

  final IClientUseCases _useCases;

  /// Lista de clientes filtrada por [search].
  late final KortexResource<List<Client>> clients;

  /// Termo de busca por nome (`''` = todos).
  final KortexSignal<String> search = KortexSignal('');

  /// Mensagem de erro da ultima acao.
  final KortexSignal<String> error = KortexSignal('');

  /// Recarrega a lista aplicando a busca ativa.
  Future<void> refresh() => clients.refresh();

  /// Cadastra um cliente; devolve `true` em caso de sucesso.
  Future<bool> createClient(String name, String phone) async {
    final result = await _useCases.createClient(name: name, phone: phone);
    if (result is Fail<Client>) {
      _publishError(result.message);
      return false;
    }
    error.value = '';
    await refresh();
    return true;
  }

  /// Limpa a mensagem de erro (apos exibida em `SnackBar`).
  void clearError() {
    error.value = '';
  }

  Future<List<Client>> _load() => _useCases.listClients(search: search.peek());

  void _publishError(String message) {
    error.value = message;
  }
}

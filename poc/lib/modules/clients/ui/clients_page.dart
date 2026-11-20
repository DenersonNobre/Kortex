/// Pagina de Clientes da POC (`StatelessWidget`).
///
/// SRP: listar/buscar clientes e abrir o dialog de cadastro.
/// NAO faz: estado de negocio (papel do controller).
///
/// Patterns: `IKortexPage` + `KortexWatch` + `KortexListener` (erro).
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../visits/domain/.index.dart';
import 'clients_controller.dart';
import 'widgets/new_client_dialog.dart';

/// Tela de clientes (site atendido).
class ClientsPage extends IKortexPage<ClientsController> {
  /// Cria a pagina de clientes.
  const ClientsPage({super.key});

  @override
  Widget buildPage(BuildContext context, ClientsController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        key: const Key('clients-new'),
        tooltip: 'Novo cliente',
        onPressed: () => showNewClientDialog(context),
        child: const Icon(Icons.add),
      ),
      body: KortexListener<String>(
        watch: () => controller.error.value,
        listener: (listenerContext, message) {
          if (message.isEmpty) return;
          ScaffoldMessenger.of(listenerContext)
              .showSnackBar(SnackBar(content: Text(message)));
          _clearLater(controller);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                key: const Key('clients-search'),
                decoration: const InputDecoration(
                  labelText: 'Buscar por nome',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  controller.search.value = value;
                  controller.refresh();
                },
              ),
            ),
            Expanded(child: _ClientsBody(controller: controller)),
          ],
        ),
      ),
    );
  }

  void _clearLater(ClientsController controller) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.clearError(),
    );
  }
}

/// Corpo com os tres estados de `IKortexAsyncState`.
class _ClientsBody extends StatelessWidget {
  const _ClientsBody({required this.controller});

  final ClientsController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final state = controller.clients.state.value;
        return switch (state) {
          KortexAsyncLoading<List<Client>>() => const Center(
            child: CircularProgressIndicator(),
          ),
          KortexAsyncError<List<Client>>() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Falha ao carregar os clientes'),
                TextButton(
                  key: const Key('clients-retry'),
                  onPressed: controller.refresh,
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
          KortexAsyncData<List<Client>>(value: final clients) =>
            clients.isEmpty
                ? const Center(child: Text('Nenhum cliente'))
                : ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        key: Key('client-${client.id}'),
                        leading: const Icon(Icons.business),
                        title: Text(client.name),
                        subtitle: Text(client.phone),
                      );
                    },
                  ),
        };
      },
    );
  }
}

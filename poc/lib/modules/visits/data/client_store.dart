/// Store em memoria de clientes, com latencia e falha simuladas.
///
/// SRP: implementar `ClientRepository` sobre um `Map`, simulando I/O.
/// NAO faz: regra de negocio nem persistencia real.
///
/// Patterns: Adapter + injecao de falha (`failNext`).
/// Dependencias: dominio + `dart:async` (puro, sem Flutter).
library;

import 'dart:async';

import '../domain/client.dart';
import '../domain/visit_repository.dart';

/// Store volatil de clientes com latencia simulada.
class InMemoryClientStore implements ClientRepository {
  /// Cria o store com [latency] de espera por operacao.
  InMemoryClientStore({this.latency = const Duration(milliseconds: 200)});

  /// Espera aplicada antes de resolver cada operacao.
  final Duration latency;

  /// Quando `true`, a proxima operacao falha com [error].
  var failNext = false;

  /// Erro usado quando [failNext] e' `true`.
  Object? error;

  final Map<int, Client> _store = {};
  var _sequence = 0;

  @override
  Future<List<Client>> listClients() async {
    await _delay();
    final clients = List.of(_store.values);
    clients.sort((a, b) => a.id.compareTo(b.id));
    return clients;
  }

  @override
  Future<Client?> findClientById(int id) async {
    await _delay();
    return _store[id];
  }

  @override
  Future<Client> saveClient(Client client) async {
    await _delay();
    if (client.id != 0) {
      _store[client.id] = client;
      return client;
    }
    final created = client.withId(++_sequence);
    _store[created.id] = created;
    return created;
  }

  Future<void> _delay() async {
    await Future<void>.delayed(latency);
    if (!failNext) return;
    failNext = false;
    throw error ?? StateError('Falha simulada no acesso aos dados.');
  }
}

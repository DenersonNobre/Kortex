/// Store em memoria de visitas, com latencia e falha simuladas.
///
/// SRP: implementar `IVisitRepository` sobre um `Map`, simulando I/O de rede
/// (demora e falha). NAO faz: regra de negocio nem persistencia real.
///
/// Patterns: Adapter + injecao de falha (`failNext`).
/// Dependencias: dominio + `dart:async` (puro, sem Flutter).
library;

import 'dart:async';

import '../domain/visit.dart';
import '../domain/visit_repository.dart';

/// Store volatil de visitas com latencia simulada.
class InMemoryVisitStore implements IVisitRepository {
  /// Cria o store com [latency] de espera por operacao.
  InMemoryVisitStore({this.latency = const Duration(milliseconds: 200)});

  /// Espera aplicada antes de resolver cada operacao.
  final Duration latency;

  /// Quando `true`, a proxima operacao falha com [error].
  var failNext = false;

  /// Erro usado quando [failNext] e' `true`.
  Object? error;

  final Map<int, Visit> _store = {};
  var _sequence = 0;

  @override
  Future<List<Visit>> listVisits() async {
    await _delay();
    final visits = List.of(_store.values);
    visits.sort((a, b) => a.id.compareTo(b.id));
    return visits;
  }

  @override
  Future<Visit?> findVisitById(int id) async {
    await _delay();
    return _store[id];
  }

  @override
  Future<Visit> saveVisit(Visit visit) async {
    await _delay();
    if (visit.id == 0) {
      return _insert(visit);
    }
    _store[visit.id] = visit;
    return visit;
  }

  @override
  Future<void> deleteVisit(int id) async {
    await _delay();
    _store.remove(id);
  }

  Visit _insert(Visit visit) {
    final created = visit.withId(++_sequence);
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

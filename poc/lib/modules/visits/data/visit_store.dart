/// Store em memoria de visitas, com latencia e falha simuladas.
///
/// SRP: implementar `IVisitRepository` sobre um `Map`, simulando I/O de rede
/// (demora e falha). NAO faz: regra de negocio nem persistencia real.
///
/// Patterns: Adapter + injecao de falha (`failNext`).
/// Dependencias: dominio + `dart:async` (puro, sem Flutter).
library;

import 'dart:async';

import '../../../core/result.dart';
import '../domain/scheduled_at.dart';
import '../domain/visit.dart';
import '../domain/visit_repository.dart';

/// Store volatil de visitas com latencia simulada.
class InMemoryVisitStore implements IVisitRepository {
  /// Cria o store com [latency] de espera por operacao.
  InMemoryVisitStore({
    this.latency = const Duration(milliseconds: 200),
    bool seedDemo = false,
  }) {
    if (!seedDemo) return;
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, 9);
    final seeds = [
      (
        clientId: 1,
        title: 'Manutencao preventiva servidor',
        when: base.add(const Duration(days: 3)),
      ),
      (
        clientId: 2,
        title: 'Inspecao rede eletrica',
        when: base.add(const Duration(days: 3, hours: 5)),
      ),
      (
        clientId: 3,
        title: 'Troca de roteador PDV',
        when: base.add(const Duration(days: 5)),
      ),
      (
        clientId: 4,
        title: 'Calibracao projetores sala 4',
        when: base.add(const Duration(days: 7)),
      ),
      (
        clientId: 5,
        title: 'Revisao balanca fiscal',
        when: base.add(const Duration(days: 7, hours: 3)),
      ),
      (
        clientId: 2,
        title: 'Auditoria backup em nuvem',
        when: base.add(const Duration(days: 7, hours: 6)),
      ),
      (
        clientId: 3,
        title: 'Instalacao nobreak caixa 2',
        when: base.subtract(const Duration(days: 2)),
      ),
    ];
    for (final seed in seeds) {
      final scheduled = ScheduledAt.create(
        seed.when,
        now: base.subtract(const Duration(days: 10)),
      );
      if (scheduled is! Success<ScheduledAt, AppFailure>) continue;
      final result = Visit.draft(
        clientId: seed.clientId,
        technicianName: 'Tecnico Demo',
        title: seed.title,
        scheduledAt: scheduled.value,
      );
      if (result is Success<Visit, AppFailure>) {
        final created = result.value.withId(++_sequence);
        _store[created.id] = created;
      }
    }
  }

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

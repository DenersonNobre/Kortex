/// Store em memoria de tecnicos, com latencia e falha simuladas.
///
/// SRP: implementar `TechnicianRepository` sobre um `Map`, simulando I/O.
/// NAO faz: regra de negocio nem persistencia real.
///
/// Patterns: Adapter + injecao de falha (`failNext`).
/// Dependencias: dominio + `dart:async` (puro, sem Flutter).
library;

import 'dart:async';

import '../domain/technician.dart';
import '../domain/visit_repository.dart';

/// Store volatil de tecnicos com latencia simulada.
class InMemoryTechnicianStore implements TechnicianRepository {
  /// Cria o store com [latency] de espera por operacao.
  InMemoryTechnicianStore({this.latency = const Duration(milliseconds: 200)});

  /// Espera aplicada antes de resolver cada operacao.
  final Duration latency;

  /// Quando `true`, a proxima operacao falha com [error].
  var failNext = false;

  /// Erro usado quando [failNext] e' `true`.
  Object? error;

  final Map<int, Technician> _store = {};
  var _sequence = 0;

  @override
  Future<List<Technician>> listTechnicians() async {
    await _delay();
    final technicians = List.of(_store.values);
    technicians.sort((a, b) => a.id.compareTo(b.id));
    return technicians;
  }

  @override
  Future<Technician?> findTechnicianById(int id) async {
    await _delay();
    return _store[id];
  }

  @override
  Future<Technician> saveTechnician(Technician technician) async {
    await _delay();
    if (technician.id != 0) {
      _store[technician.id] = technician;
      return technician;
    }
    final created = technician.withId(++_sequence);
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

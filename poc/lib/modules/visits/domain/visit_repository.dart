/// Porta de persistencia do agregado visita.
///
/// SRP: contrato minimo de leitura e escrita das visitas. NAO faz: validar
/// regras nem escolher tecnologia de armazenamento.
///
/// Patterns: Port explicita (ISP: so o que as features usam).
/// Dependencias: entidade do dominio (puro, sem Flutter).
library;

import 'visit.dart';

/// Contrato de leitura e escrita das visitas.
abstract interface class VisitRepository {
  /// Lista todas as visitas (ordenadas por `id`).
  Future<List<Visit>> listVisits();

  /// Busca por [id] ou `null` quando ausente.
  Future<Visit?> findVisitById(int id);

  /// Insere (gera `id` quando `0`) ou substitui pelo `id`.
  Future<Visit> saveVisit(Visit visit);

  /// Remove por [id]; ausente e' no-op.
  Future<void> deleteVisit(int id);
}

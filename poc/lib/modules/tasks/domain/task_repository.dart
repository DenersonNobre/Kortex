/// Porta de persistência de tasks (`TaskRepository`).
///
/// SRP: contrato mínimo de CRUD síncrono para o agregado `Task`.
/// NÃO faz: validar regras (domínio), escolher tecnologia nem I/O real.
///
/// Patterns: Port explícita (ISP: só o que as features usam).
/// Dependências: apenas a entidade (puro, sem infra).
library;

import 'task.dart';

/// Contrato de persistência usado pelos commands e pela query.
abstract interface class TaskRepository {
  /// Lista todas ordenadas por `id`.
  List<Task> findAll();

  /// Busca por [id] ou `null` quando ausente.
  Task? findById(int id);

  /// Insere (gera `id` quando `0`) ou substitui pelo `id`.
  Task save(Task task);

  /// Remove por [id]; ausente é no-op.
  void deleteById(int id);
}

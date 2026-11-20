/// Mutação de remoção de task (`RemoveTaskCommand`).
///
/// SRP: remover por `id` devolvendo a removida.
/// NÃO faz: validar texto nem tocar em categorias.
///
/// Patterns: Command com `Result` (falha esperada sem exceção).
/// Dependências: port de tasks + contrato de falha (puro).
library;

import '../../../core/result.dart';
import '../domain/.index.dart';

/// Remove por `id` e devolve a removida.
class RemoveTaskCommand {
  /// Cria o command sobre [tasks].
  const RemoveTaskCommand(this._tasks);

  final TaskRepository _tasks;

  /// Remove ou `Fail` (`TASK_NOT_FOUND`).
  Result<Task> call(int id) {
    final task = _tasks.findById(id);
    if (task == null) {
      return const Fail(TaskFailureCodes.notFound, 'Task inexistente.');
    }
    _tasks.deleteById(id);
    return Ok(task);
  }
}

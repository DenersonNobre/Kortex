/// Mutação de remoção de task (`RemoveTaskCommand`).
///
/// SRP: remover por `id` devolvendo a removida.
/// NÃO faz: validar texto nem tocar em categorias.
///
/// Patterns: Command com `IResult` (falha esperada sem exceção).
/// Dependências: port de tasks + contrato de falha (puro).
library;

import '../../../core/result.dart';
import '../domain/.index.dart';

/// Remove por `id` e devolve a removida.
class RemoveTaskCommand {
  /// Cria o command sobre [tasks].
  const RemoveTaskCommand(this._tasks);

  final ITaskRepository _tasks;

  /// Remove ou `Fail` (`TASK_NOT_FOUND`).
  IResult<Task> call(int id) {
    final task = _tasks.findById(id);
    if (task == null) {
      return const Fail(TaskFailureCodes.notFound, 'Task inexistente.');
    }
    _tasks.deleteById(id);
    return Ok(task);
  }
}

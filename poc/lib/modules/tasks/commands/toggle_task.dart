/// Mutação de alternância de conclusão (`ToggleTaskCommand`).
///
/// SRP: inverter `done` com `Fail` para id ausente. NÃO faz: validar texto
/// nem tocar em categorias.
///
/// Patterns: Command com `IResult` (falha esperada sem exceção).
/// Dependências: port de tasks + contrato de falha (puro).
library;

import '../../../core/result.dart';
import '../domain/.index.dart';

/// Alterna `done` preservando demais campos.
class ToggleTaskCommand {
  /// Cria o command sobre [tasks].
  const ToggleTaskCommand(this._tasks);

  final ITaskRepository _tasks;

  /// Inverte `done` ou `Fail` (`TASK_NOT_FOUND`).
  IResult<Task> call(int id) {
    final task = _tasks.findById(id);
    if (task == null) {
      return const Fail(TaskFailureCodes.notFound, 'Task inexistente.');
    }
    return Ok(_tasks.save(task.toggle()));
  }
}

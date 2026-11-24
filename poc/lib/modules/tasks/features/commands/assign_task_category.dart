/// Mutação de vínculo task↔categoria (`AssignTaskCategoryCommand`).
///
/// SRP: vincular (`categoryId`) ou desvincular (`null`), validando os dois
/// lados. NÃO faz: criar categorias nem validar texto.
///
/// Patterns: Command coordenando dois agregados com `IResult`.
/// Dependências: ports dos dois agregados (puro).
library;

import '../../../../core/result.dart';
import '../../domain/.index.dart';

/// Vincula/desvincula preservando os demais campos da task.
class AssignTaskCategoryCommand {
  /// Cria o command sobre [tasks] e [categories].
  const AssignTaskCategoryCommand(this._tasks, this._categories);

  final ITaskRepository _tasks;
  final ICategoryRepository _categories;

  /// Vincula [categoryId] (`null` desvincula) ou `Fail` com o código.
  AppResult<Task> call(int taskId, int? categoryId) {
    final task = _tasks.findById(taskId);
    if (task == null) {
      return const Failure(AppFailure(TaskFailureCodes.notFound, 'Task inexistente.'));
    }
    if (categoryId != null && _categories.findById(categoryId) == null) {
      return const Failure(AppFailure(
        CategoryFailureCodes.notFound,
        'Categoria inexistente.',
      ));
    }
    return Success(
      _tasks.save(
        Task(
          id: task.id,
          title: task.title,
          done: task.done,
          categoryId: categoryId,
        ),
      ),
    );
  }
}

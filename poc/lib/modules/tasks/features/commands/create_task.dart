/// Mutação de criação de task (`CreateTaskCommand`).
///
/// SRP: validar título (+ existência da categoria) e persistir.
/// NÃO faz: ler para UI nem decidir apresentação do erro.
///
/// Patterns: Command com `IResult` (falha esperada sem exceção).
/// Dependências: ports dos dois agregados (puro).
library;

import '../../../../core/result.dart';
import '../../domain/.index.dart';

/// Cria task (com categoria opcional previamente existente).
class CreateTaskCommand {
  /// Cria o command sobre [tasks] e [categories].
  const CreateTaskCommand(this._tasks, this._categories);

  final ITaskRepository _tasks;
  final ICategoryRepository _categories;

  /// Valida e persiste; `Fail` não persiste nada.
  AppResult<Task> call(String rawTitle, {int? categoryId}) {
    if (categoryId != null && _categories.findById(categoryId) == null) {
      return const Failure(
        AppFailure(
          CategoryFailureCodes.notFound,
          'Categoria inexistente.',
        ),
      );
    }
    final draft = Task.draft(rawTitle, categoryId: categoryId);
    if (draft is Failure<Task, AppFailure>) {
      return draft;
    }
    return Success(_tasks.save((draft as Success<Task, AppFailure>).value));
  }
}

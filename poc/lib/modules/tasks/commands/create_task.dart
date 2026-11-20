/// Mutação de criação de task (`CreateTaskCommand`).
///
/// SRP: validar título (+ existência da categoria) e persistir.
/// NÃO faz: ler para UI nem decidir apresentação do erro.
///
/// Patterns: Command com `Result` (falha esperada sem exceção).
/// Dependências: ports dos dois agregados (puro).
library;

import '../../../core/result.dart';
import '../domain/.index.dart';

/// Cria task (com categoria opcional previamente existente).
class CreateTaskCommand {
  /// Cria o command sobre [tasks] e [categories].
  const CreateTaskCommand(this._tasks, this._categories);

  final TaskRepository _tasks;
  final CategoryRepository _categories;

  /// Valida e persiste; `Fail` não persiste nada.
  Result<Task> call(String rawTitle, {int? categoryId}) {
    if (categoryId != null && _categories.findById(categoryId) == null) {
      return const Fail(
        CategoryFailureCodes.notFound,
        'Categoria inexistente.',
      );
    }
    final draft = Task.draft(rawTitle, categoryId: categoryId);
    if (draft is Fail<Task>) {
      return draft;
    }
    return Ok(_tasks.save((draft as Ok<Task>).value));
  }
}

/// Mutação de exclusão de categoria (`DeleteCategoryCommand`).
///
/// SRP: excluir com invariante "categoria em uso não exclui".
/// NÃO faz: excluir tasks (só bloqueia enquanto referenciada).
///
/// Patterns: Command coordenando dois agregados (guarda cross-aggregate).
/// Dependências: ports dos dois agregados (puro).
library;

import '../../../../core/result.dart';
import '../../domain/.index.dart';

/// Exclui categoria livre, devolvendo a excluída.
class DeleteCategoryCommand {
  /// Cria o command sobre [categories] e [tasks].
  const DeleteCategoryCommand(this._categories, this._tasks);

  final ICategoryRepository _categories;
  final ITaskRepository _tasks;

  /// Exclui, ou `Fail` (`CATEGORY_NOT_FOUND`, `CATEGORY_IN_USE`).
  IResult<Category> call(int id) {
    final category = _categories.findById(id);
    if (category == null) {
      return const Fail(
        CategoryFailureCodes.notFound,
        'Categoria inexistente.',
      );
    }
    if (_inUse(id)) {
      return const Fail(
        CategoryFailureCodes.inUse,
        'Categoria em uso por tasks.',
      );
    }
    _categories.deleteById(id);
    return Ok(category);
  }

  bool _inUse(int id) => _tasks.findAll().any((task) => task.categoryId == id);
}

/// Mutação de criação de categoria (`CreateCategoryCommand`).
///
/// SRP: validar nome/cor via VOs e persistir. NÃO faz: vincular tasks.
/// Dependências: port de categorias (puro).
library;

import '../../../../core/result.dart';
import '../../domain/.index.dart';

/// Cria categorias com VOs validados.
class CreateCategoryCommand {
  /// Cria o command sobre [categories].
  const CreateCategoryCommand(this._categories);

  final ICategoryRepository _categories;

  /// Valida e persiste, ou `Fail` do VO (nada persiste).
  AppResult<Category> call(String name, String color) {
    final draft = Category.draft(name, color);
    if (draft is Failure<Category, AppFailure>) {
      return draft;
    }
    return Success(
      _categories.save((draft as Success<Category, AppFailure>).value),
    );
  }
}

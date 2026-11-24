/// Query de listagem de categorias (`ListCategoriesQuery`).
///
/// SRP: consultar categorias ordenadas. NÃO faz: mutar estado.
/// Dependências: port do agregado (puro).
library;

import '../../domain/.index.dart';

/// Query de listagem de categorias.
class ListCategoriesQuery {
  /// Cria a query sobre [categories].
  const ListCategoriesQuery(this._categories);

  final ICategoryRepository _categories;

  /// Lista todas ordenadas por `id`.
  List<Category> call() => _categories.findAll();
}

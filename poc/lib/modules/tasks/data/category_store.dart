/// Adapter em memória de `ICategoryRepository` (teste e POC).
///
/// SRP: implementar o contrato do port com `Map` + sequência monotônica.
/// NÃO faz: I/O nem validação (papel do domínio).
///
/// Patterns: Adapter + Test Double natural.
/// Dependências: domínio + `dart:core` (puro).
library;

import '../domain/category.dart';
import '../domain/category_repository.dart';

/// Repositório volátil com ids sequenciais a partir de 1.
class CategoryStore implements ICategoryRepository {
  final Map<int, Category> _store = {};
  var _sequence = 0;

  @override
  List<Category> findAll() {
    final categories = List.of(_store.values);
    categories.sort((a, b) => a.id.compareTo(b.id));
    return categories;
  }

  @override
  Category? findById(int id) => _store[id];

  @override
  Category save(Category category) {
    if (category.id == 0) {
      return _insert(category);
    }
    _store[category.id] = category;
    return category;
  }

  @override
  void deleteById(int id) {
    _store.remove(id);
  }

  Category _insert(Category category) {
    final created = Category(
      id: ++_sequence,
      name: category.name,
      color: category.color,
    );
    _store[created.id] = created;
    return created;
  }
}

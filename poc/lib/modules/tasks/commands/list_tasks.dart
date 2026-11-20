/// Leitura de tasks com join de categoria (`ListTasksQuery`).
///
/// SRP: consultar tasks e enriquecer com o nome da categoria.
/// NÃO faz: mutar estado nem validar entrada.
///
/// Patterns: CQRS leve (leitura direta, sem entidades pesadas).
/// Dependências: ports dos dois agregados (puro).
library;

import '../domain/.index.dart';
import '../task_view.dart';

/// Query de listagem (`all`) e filtro por categoria (`byCategory`).
class ListTasksQuery {
  /// Cria a query sobre [tasks] e [categories].
  const ListTasksQuery(this._tasks, this._categories);

  final TaskRepository _tasks;
  final CategoryRepository _categories;

  /// Lista todas ordenadas por `id`, com nomes resolvidos.
  List<TaskView> all() => _views(_tasks.findAll());

  /// Filtra por [categoryId] (`null` = sem categoria).
  List<TaskView> byCategory(int? categoryId) =>
      _views(_tasks.findAll().where((task) => task.categoryId == categoryId));

  List<TaskView> _views(Iterable<Task> tasks) {
    final names = <int, String>{
      for (final category in _categories.findAll())
        category.id: category.name.value,
    };
    return [
      for (final task in tasks)
        TaskView(
          id: task.id,
          title: task.title.value,
          done: task.done,
          categoryId: task.categoryId,
          categoryName: task.categoryId == null ? null : names[task.categoryId],
        ),
    ];
  }
}

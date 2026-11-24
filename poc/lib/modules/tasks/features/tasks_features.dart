/// Fachada de casos de uso do módulo de tasks (`ITaskUseCases`).
///
/// SRP: agregar os casos de uso num único contrato injetável, evitando
/// over-injection no controller. NÃO faz: regra de negócio (vive nos
/// commands/queries) nem I/O.
///
/// Patterns: Facade de UseCases (CQRS sem Mediator).
/// Dependências: commands e queries via barrels (puro, sem UI).
library;

import '../../../core/result.dart';
import 'commands/.index.dart';
import 'queries/.index.dart';
import '../domain/.index.dart';

/// Contrato único consumido pelo controller (1 dependência).
abstract interface class ITaskUseCases {
  /// Lista todas as tasks com categorias resolvidas.
  List<TaskRow> listAll();

  /// Filtra por categoria (`null` = sem categoria).
  List<TaskRow> listByCategory(int? categoryId);

  /// Lista as categorias ordenadas por `id`.
  List<Category> listCategories();

  /// Cria task (categoria opcional previamente existente).
  AppResult<Task> create(String rawTitle, {int? categoryId});

  /// Inverte `done` da task.
  AppResult<Task> toggle(int id);

  /// Remove e devolve a removida.
  AppResult<Task> remove(int id);

  /// Vincula (`categoryId`) ou desvincula (`null`) a categoria.
  AppResult<Task> assignCategory(int taskId, int? categoryId);

  /// Cria categoria com VOs validados.
  AppResult<Category> createCategory(String name, String color);

  /// Exclui categoria livre, devolvendo a excluída.
  AppResult<Category> deleteCategory(int id);
}

/// Implementação padrão compondo commands e queries.
class DefaultTaskUseCases implements ITaskUseCases {
  /// Monta a fachada sobre os repositórios [tasks] e [categories].
  DefaultTaskUseCases({
    required ITaskRepository tasks,
    required ICategoryRepository categories,
  }) : _listQuery = ListTasksQuery(tasks, categories),
       _listCategories = ListCategoriesQuery(categories),
       _create = CreateTaskCommand(tasks, categories),
       _toggle = ToggleTaskCommand(tasks),
       _remove = RemoveTaskCommand(tasks),
       _assign = AssignTaskCategoryCommand(tasks, categories),
       _createCategory = CreateCategoryCommand(categories),
       _deleteCategory = DeleteCategoryCommand(categories, tasks);

  final ListTasksQuery _listQuery;
  final ListCategoriesQuery _listCategories;
  final CreateTaskCommand _create;
  final ToggleTaskCommand _toggle;
  final RemoveTaskCommand _remove;
  final AssignTaskCategoryCommand _assign;
  final CreateCategoryCommand _createCategory;
  final DeleteCategoryCommand _deleteCategory;

  @override
  List<TaskRow> listAll() => _listQuery.all();

  @override
  List<TaskRow> listByCategory(int? categoryId) =>
      _listQuery.byCategory(categoryId);

  @override
  List<Category> listCategories() => _listCategories();

  @override
  AppResult<Task> create(String rawTitle, {int? categoryId}) =>
      _create(rawTitle, categoryId: categoryId);

  @override
  AppResult<Task> toggle(int id) => _toggle(id);

  @override
  AppResult<Task> remove(int id) => _remove(id);

  @override
  AppResult<Task> assignCategory(int taskId, int? categoryId) =>
      _assign(taskId, categoryId);

  @override
  AppResult<Category> createCategory(String name, String color) =>
      _createCategory(name, color);

  @override
  AppResult<Category> deleteCategory(int id) => _deleteCategory(id);
}

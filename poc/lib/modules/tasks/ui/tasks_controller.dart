/// Controller reativo da POC de tasks.
///
/// SRP: expor lista filtrada, categorias, rascunho e erro, delegando toda a
/// regra ao `ITaskUseCases`. NAO faz: UI, navegacao ou persistencia direta.
///
/// Patterns: `IKortexController` (sinais + `disposeBag`), inicializacao no
/// construtor. Dependencias: `kortex` + camada `features` da POC.
library;

import 'package:kortex/kortex.dart';

import '../../../core/result.dart';
import '../../../core/ui/error_feedback_mixin.dart';
import '../domain/.index.dart';
import '../features/tasks_features.dart';
import '../features/queries/task_row.dart';
import 'task_draft.dart';

/// Controller da `TasksPage`.
class TasksController extends IKortexController with KortexErrorMixin {
  /// Registra os sinais e a fachada no `disposeBag` (descarte automatico).
  TasksController(this._useCases) {
    autoDispose(tasks);
    autoDispose(categories);
    autoDispose(filter);
    autoDispose(showCategoryForm);
  }

  final ITaskUseCases _useCases;

  /// Tasks visiveis (respeitam o filtro de categoria ativo).
  final KortexSignal<List<TaskRow>> tasks = KortexSignal(const []);

  /// Categorias cadastradas.
  final KortexSignal<List<Category>> categories = KortexSignal(const []);

  /// Categoria ativa do filtro (`null` = todas).
  final KortexSignal<int?> filter = KortexSignal(null);

  /// Exibe o formulario de categoria.
  final KortexSignal<bool> showCategoryForm = KortexSignal(false);

  /// Rascunho editado pelo formulario.
  final TaskDraft draft = TaskDraft();

  /// Recarrega a lista aplicando o filtro ativo.
  ///
  /// Sem filtro ativo, lista todas; com filtro, lista por categoria.
  void refresh() {
    final categoryId = filter.peek();
    tasks.value = categoryId == null
        ? _useCases.listAll()
        : _useCases.listByCategory(categoryId);
  }

  /// Recarrega as categorias.
  void refreshCategories() {
    categories.value = _useCases.listCategories();
  }

  /// Aplica o filtro de categoria e recarrega a lista.
  void applyFilter(int? categoryId) {
    filter.value = categoryId;
    refresh();
  }

  /// Cria a task a partir do rascunho; devolve `true` em caso de sucesso.
  bool createTask() {
    final result = _useCases.create(draft.title, categoryId: draft.categoryId);
    if (result is Failure<Task, AppFailure>) {
      publishError(result.message);
      return false;
    }
    error.value = '';
    draft.clear();
    refresh();
    return true;
  }

  /// Alterna a conclusao da task [id]; devolve `true` em caso de sucesso.
  bool toggleTask(int id) {
    final result = _useCases.toggle(id);
    if (result is Failure<Task, AppFailure>) {
      publishError(result.message);
      return false;
    }
    error.value = '';
    refresh();
    return true;
  }

  /// Remove a task [id]; devolve `true` em caso de sucesso.
  bool removeTask(int id) {
    final result = _useCases.remove(id);
    if (result is Failure<Task, AppFailure>) {
      publishError(result.message);
      return false;
    }
    error.value = '';
    refresh();
    return true;
  }

  /// Cria a categoria; devolve `true` em caso de sucesso.
  bool createCategory(String name, String colorHex) {
    final result = _useCases.createCategory(name, colorHex);
    if (result is Failure<Category, AppFailure>) {
      publishError(result.message);
      return false;
    }
    error.value = '';
    refreshCategories();
    return true;
  }

  /// Exclui a categoria [id]; devolve `true` em caso de sucesso.
  bool removeCategory(int id) {
    final result = _useCases.deleteCategory(id);
    if (result is Failure<Category, AppFailure>) {
      publishError(result.message);
      return false;
    }
    error.value = '';
    refreshCategories();
    refresh();
    return true;
  }

  /// Alterna a exibicao do formulario de categoria.
  void toggleCategoryForm() {
    showCategoryForm.value = !showCategoryForm.peek();
  }

  /// Limpa a mensagem de erro (apos exibida em `SnackBar`).
}

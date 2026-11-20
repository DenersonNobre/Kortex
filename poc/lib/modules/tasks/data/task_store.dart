/// Adapter em memória de `TaskRepository` (teste e POC).
///
/// SRP: implementar o contrato do port com `Map` + sequência monotônica.
/// NÃO faz: I/O, concorrência entre isolates nem migração de schema.
///
/// Patterns: Adapter + Test Double natural (o próprio adapter serve de
/// fake nos testes de commands e usecases).
/// Dependências: domínio + `dart:core` (puro).
library;

import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Repositório volátil com ids sequenciais a partir de 1.
class TaskStore implements TaskRepository {
  final Map<int, Task> _store = {};
  var _sequence = 0;

  @override
  List<Task> findAll() {
    final tasks = List.of(_store.values);
    tasks.sort((a, b) => a.id.compareTo(b.id));
    return tasks;
  }

  @override
  Task? findById(int id) => _store[id];

  @override
  Task save(Task task) {
    if (task.id == 0) {
      return _insert(task);
    }
    _store[task.id] = task;
    return task;
  }

  @override
  void deleteById(int id) {
    _store.remove(id);
  }

  Task _insert(Task task) {
    final created = Task(
      id: ++_sequence,
      title: task.title,
      done: task.done,
      categoryId: task.categoryId,
    );
    _store[created.id] = created;
    return created;
  }
}

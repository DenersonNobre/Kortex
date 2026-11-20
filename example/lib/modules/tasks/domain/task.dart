/// Entidade imutável `Task` + fábrica validada (`draft`).
///
/// SRP: identidade (`id`), título validado e estado (`done`) com
/// transições que devolvem novas instâncias. NÃO faz: validar texto
/// (papel do VO `TaskTitle`) nem persistir (papel do repositório).
///
/// Patterns: Entidade imutável + Factory que propaga `Fail` do VO.
/// Dependências: `shared/result.dart` + domínio (puro).
library;

import '../../../shared/result.dart';
import 'task_title.dart';

/// Task com `id` (`0` = transiente, ainda não persistida).
final class Task {
  /// Cria a task com [id], [title] e [done].
  const Task({required this.id, required this.title, this.done = false});

  /// Identificador (`0` antes da primeira persistência).
  final int id;

  /// Título sempre válido.
  final TaskTitle title;

  /// Verdadeiro quando concluída.
  final bool done;

  /// Valida [rawTitle] e devolve a transiente (`id: 0`) ou o `Fail` do VO.
  static Result<Task> draft(String rawTitle) {
    final title = TaskTitle.create(rawTitle);
    if (title is Fail<TaskTitle>) {
      return Fail<Task>(title.code, title.message);
    }
    return Ok(Task(id: 0, title: (title as Ok<TaskTitle>).value));
  }

  /// Devolve cópia com `done` invertido (original intacto).
  Task toggle() => Task(id: id, title: title, done: !done);
}

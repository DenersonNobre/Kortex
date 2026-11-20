/// Entidade imutável `Task` + fábrica validada (`draft`).
///
/// SRP: identidade (`id`), título validado e estado (`done`) com
/// transições que devolvem novas instâncias. NÃO faz: validar texto
/// (papel do VO `TaskTitle`) nem persistir (papel do repositório).
///
/// Patterns: Entidade imutável + Factory que propaga `Fail` do VO.
/// Dependências: `shared/result.dart` + domínio (puro).
library;

import '../../../core/result.dart';
import 'task_title.dart';

/// Task com `id` (`0` = transiente, ainda não persistida).
final class Task {
  /// Cria a task com [id], [title], [done] e [categoryId] opcional.
  const Task({
    required this.id,
    required this.title,
    this.done = false,
    this.categoryId,
  });

  /// Identificador (`0` antes da primeira persistência).
  final int id;

  /// Título sempre válido.
  final TaskTitle title;

  /// Verdadeiro quando concluída.
  final bool done;

  /// Categoria vinculada (`null` = sem categoria).
  final int? categoryId;

  /// Valida [rawTitle] e devolve a transiente (`id: 0`) ou o `Fail` do VO.
  ///
  /// A existência de [categoryId] é validada pelo command (não pelo VO).
  static Result<Task> draft(String rawTitle, {int? categoryId}) {
    final title = TaskTitle.create(rawTitle);
    if (title is Fail<TaskTitle>) {
      return Fail<Task>(title.code, title.message);
    }
    return Ok(
      Task(
        id: 0,
        title: (title as Ok<TaskTitle>).value,
        categoryId: categoryId,
      ),
    );
  }

  /// Devolve cópia com `done` invertido (original intacto).
  Task toggle() =>
      Task(id: id, title: title, done: !done, categoryId: categoryId);
}

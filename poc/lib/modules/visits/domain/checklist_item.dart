/// Item do checklist da visita (`ChecklistItem`).
///
/// SRP: descrever uma tarefa de atendimento e seu estado de conclusao.
/// NAO faz: persistencia nem regra de transicao da visita.
///
/// Patterns: Entidade imutavel + fabrica que devolve `IResult`.
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'visit_failures.dart';

/// Item de checklist sempre valido (construcao so via `create`).
final class ChecklistItem {
  const ChecklistItem._({
    required this.id,
    required this.description,
    this.done = false,
  });

  /// Identificador do item dentro da visita.
  final int id;

  /// Descricao normalizada do item.
  final String description;

  /// Concluido ou nao.
  final bool done;

  /// Valida [description] e devolve `Ok` ou `Fail` com codigo estavel.
  static IResult<ChecklistItem> create({
    required String description,
    int id = 0,
  }) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      return const Fail(
        VisitFailureCodes.checklistDescriptionEmpty,
        'Item do checklist nao pode ter descricao vazia.',
      );
    }
    return Ok(ChecklistItem._(id: id, description: trimmed));
  }

  /// Devolve copia com a conclusao invertida.
  ChecklistItem toggle() =>
      ChecklistItem._(id: id, description: description, done: !done);
}

/// Agregado raiz da visita tecnica (`Visit`).
///
/// SRP: agregar identidade, status, checklist e referencias a cliente e
/// tecnico, com transicoes que devolvem novas instancias. NAO faz: validar
/// texto (papel dos VOs) nem persistir (papel do repositorio).
///
/// Patterns: Entidade imutavel + transicoes puras.
/// Dependencias: VOs + `core/result.dart` (puro).
library;

import '../../../core/result.dart';
import 'checklist_item.dart';
import 'visit_status.dart';
import 'visit_title.dart';

/// Visita tecnica sempre valida (construcao so via `draft`).
final class Visit {
  const Visit._({
    required this.id,
    required this.title,
    required this.clientId,
    required this.technicianId,
    required this.status,
    required this.checklist,
    this.notes = '',
  });

  /// Identificador (`0` antes da primeira persistencia).
  final int id;

  /// Titulo validado.
  final VisitTitle title;

  /// Cliente (site) atendido.
  final int clientId;

  /// Tecnico responsavel.
  final int technicianId;

  /// Situacao atual da visita.
  final VisitStatus status;

  /// Itens do checklist.
  final List<ChecklistItem> checklist;

  /// Observacoes do atendimento.
  final String notes;

  /// Fracao do checklist concluida (0 a 1; 0 quando nao ha itens).
  double get progress {
    if (checklist.isEmpty) return 0;
    final done = checklist.where((item) => item.done).length;
    return done / checklist.length;
  }

  /// Valida os campos e devolve a visita transiente ou o `Fail`.
  static Result<Visit> draft({
    required String title,
    required int clientId,
    required int technicianId,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) {
    final parsed = VisitTitle.create(title);
    if (parsed is Fail<VisitTitle>) {
      return Fail<Visit>(parsed.code, parsed.message);
    }
    return Ok(
      Visit._(
        id: 0,
        title: (parsed as Ok<VisitTitle>).value,
        clientId: clientId,
        technicianId: technicianId,
        status: VisitStatus.scheduled,
        checklist: List.of(checklist),
        notes: notes.trim(),
      ),
    );
  }

  /// Devolve copia com o [id] aplicado (persistência).
  Visit withId(int id) => Visit._(
    id: id,
    title: title,
    clientId: clientId,
    technicianId: technicianId,
    status: status,
    checklist: checklist,
    notes: notes,
  );

  /// Devolve copia com [status] aplicado.
  Visit withStatus(VisitStatus status) => Visit._(
    id: id,
    title: title,
    clientId: clientId,
    technicianId: technicianId,
    status: status,
    checklist: checklist,
    notes: notes,
  );

  /// Devolve copia com o item de checklist [index] invertido.
  Visit toggleChecklist(int index) {
    if (index < 0 || index >= checklist.length) return this;
    final updated = List.of(checklist);
    updated[index] = updated[index].toggle();
    return Visit._(
      id: id,
      title: title,
      clientId: clientId,
      technicianId: technicianId,
      status: status,
      checklist: updated,
      notes: notes,
    );
  }

  /// Devolve copia com todos os itens do checklist concluidos.
  Visit completeChecklist() {
    final updated = [
      for (final item in checklist) item.done ? item : item.toggle(),
    ];
    return Visit._(
      id: id,
      title: title,
      clientId: clientId,
      technicianId: technicianId,
      status: status,
      checklist: updated,
      notes: notes,
    );
  }
}

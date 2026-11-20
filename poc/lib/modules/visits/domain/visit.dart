/// Agregado raiz da visita tecnica (`Visit`).
///
/// SRP: agregar identidade, status, agenda, checklist e referencias a
/// cliente e tecnico, com transicoes que devolvem novas instancias.
/// NAO faz: validar texto (papel dos VOs) nem persistir (repositorio).
///
/// Patterns: Entidade imutavel + transicoes puras sobre um `_copy` unico
/// (evita esquecer campo novo em uma das copias).
/// Dependencias: VOs + `core/result.dart` (puro).
library;

import '../../../core/result.dart';
import 'checklist_item.dart';
import 'scheduled_at.dart';
import 'visit_status.dart';
import 'visit_title.dart';

/// Visita tecnica sempre valida (construcao so via `draft`).
final class Visit {
  const Visit._({
    required this.id,
    required this.title,
    required this.clientId,
    required this.technicianName,
    required this.scheduledAt,
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

  /// Nome do tecnico responsavel (snapshot do usuario da sessao).
  final String technicianName;

  /// Data e hora agendadas (sempre futuras na criacao).
  final ScheduledAt scheduledAt;

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
    required String technicianName,
    required ScheduledAt scheduledAt,
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
        technicianName: technicianName,
        scheduledAt: scheduledAt,
        status: VisitStatus.scheduled,
        checklist: List.of(checklist),
        notes: notes.trim(),
      ),
    );
  }

  /// Copia com os campos sobrescritos (unico ponto de reconstrucao).
  Visit _copy({int? id, VisitStatus? status, List<ChecklistItem>? checklist}) =>
      Visit._(
        id: id ?? this.id,
        title: title,
        clientId: clientId,
        technicianName: technicianName,
        scheduledAt: scheduledAt,
        status: status ?? this.status,
        checklist: checklist ?? this.checklist,
        notes: notes,
      );

  /// Devolve copia com o [id] aplicado (persistencia).
  Visit withId(int id) => _copy(id: id);

  /// Devolve copia com [status] aplicado.
  Visit withStatus(VisitStatus status) => _copy(status: status);

  /// Devolve copia com o item de checklist [index] invertido.
  Visit toggleChecklist(int index) {
    if (index < 0 || index >= checklist.length) return this;
    final updated = List.of(checklist);
    updated[index] = updated[index].toggle();
    return _copy(checklist: updated);
  }

  /// Devolve copia com todos os itens do checklist concluidos.
  Visit completeChecklist() => _copy(
    checklist: [for (final item in checklist) item.done ? item : item.toggle()],
  );
}

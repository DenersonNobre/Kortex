/// Mutacoes da visita tecnica (agendar, iniciar, concluir, checklist).
///
/// SRP: cada command altera um aspecto da visita e devolve `Result`.
/// NAO faz: leitura para UI nem decisao de apresentacao.
///
/// Patterns: Command por caso de uso, com guarda de invariante.
/// Dependencias: ports + dominio (puro).
library;

import '../../../core/result.dart';
import '../domain/.index.dart';

/// Agenda uma visita para um cliente e um tecnico existentes.
class ScheduleVisitCommand {
  /// Cria o command sobre [visits], [clients] e [technicians].
  const ScheduleVisitCommand(this._visits, this._clients, this._technicians);

  final VisitRepository _visits;
  final ClientRepository _clients;
  final TechnicianRepository _technicians;

  /// Agenda a visita; falha se cliente/tecnico nao existirem.
  Future<Result<Visit>> call({
    required String title,
    required int clientId,
    required int technicianId,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) async {
    final draft = Visit.draft(
      title: title,
      clientId: clientId,
      technicianId: technicianId,
      checklist: checklist,
      notes: notes,
    );
    if (draft is Fail<Visit>) {
      return draft;
    }
    if (await _clients.findClientById(clientId) == null) {
      return const Fail(
        VisitFailureCodes.clientNotFound,
        'Cliente nao encontrado.',
      );
    }
    if (await _technicians.findTechnicianById(technicianId) == null) {
      return const Fail(
        VisitFailureCodes.technicianNotFound,
        'Tecnico nao encontrado.',
      );
    }
    return Ok(await _visits.saveVisit((draft as Ok<Visit>).value));
  }
}

/// Inicia uma visita agendada.
class StartVisitCommand {
  /// Cria o command sobre [visits].
  const StartVisitCommand(this._visits);

  final VisitRepository _visits;

  /// Marca a visita como em andamento.
  Future<Result<Visit>> call(int visitId) async {
    final visit = await _visits.findVisitById(visitId);
    if (visit == null) {
      return const Fail(
        VisitFailureCodes.visitNotFound,
        'Visita nao encontrada.',
      );
    }
    if (!visit.status.canStart) {
      return const Fail(
        VisitFailureCodes.visitAlreadyStarted,
        'Visita ja iniciada.',
      );
    }
    return Ok(
      await _visits.saveVisit(visit.withStatus(VisitStatus.inProgress)),
    );
  }
}

/// Conclui uma visita em andamento (marca o checklist inteiro).
class CompleteVisitCommand {
  /// Cria o command sobre [visits].
  const CompleteVisitCommand(this._visits);

  final VisitRepository _visits;

  /// Conclui a visita e marca todos os itens do checklist.
  Future<Result<Visit>> call(int visitId) async {
    final visit = await _visits.findVisitById(visitId);
    if (visit == null) {
      return const Fail(
        VisitFailureCodes.visitNotFound,
        'Visita nao encontrada.',
      );
    }
    if (!visit.status.canComplete) {
      return const Fail(
        VisitFailureCodes.visitNotInProgress,
        'Visita nao esta em andamento.',
      );
    }
    final completed = visit.completeChecklist().withStatus(
      VisitStatus.completed,
    );
    return Ok(await _visits.saveVisit(completed));
  }
}

/// Marca ou desmarca um item do checklist.
class ToggleChecklistItemCommand {
  /// Cria o command sobre [visits].
  const ToggleChecklistItemCommand(this._visits);

  final VisitRepository _visits;

  /// Inverte o item [index] do checklist da visita.
  Future<Result<Visit>> call(int visitId, int index) async {
    final visit = await _visits.findVisitById(visitId);
    if (visit == null) {
      return const Fail(
        VisitFailureCodes.visitNotFound,
        'Visita nao encontrada.',
      );
    }
    return Ok(await _visits.saveVisit(visit.toggleChecklist(index)));
  }
}

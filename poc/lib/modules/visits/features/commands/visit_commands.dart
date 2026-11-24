/// Mutacoes da visita tecnica (agendar, iniciar, concluir, checklist).
///
/// SRP: cada command altera um aspecto da visita e devolve `IResult`.
/// NAO faz: leitura para UI nem decisao de apresentacao.
///
/// Patterns: Command por caso de uso, com guarda de invariante.
/// Dependencias: ports (visitas/clientes), sessao e dominio (puro).
library;

import '../../../../core/result.dart';
import '../../../clients/domain/.index.dart';
import '../../../session/.index.dart';
import '../../domain/.index.dart';

/// Agenda uma visita para um cliente existente, atribuida ao usuario da sessao.
class ScheduleVisitCommand {
  /// Cria o command sobre [visits] e [clients].
  ///
  /// O tecnico responsavel vem de [session]: na POC o usuario logado e' o
  /// proprio tecnico, entao a visita nasce no nome dele.
  /// [now] e' injetavel para manter o dominio deterministico nos testes.
  ScheduleVisitCommand(
    this._visits,
    this._clients,
    this._session, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final IVisitRepository _visits;
  final IClientRepository _clients;
  final ISessionProvider _session;
  final DateTime Function() _now;

  /// Agenda a visita; falha se o cliente nao existir ou a data for passada.
  Future<IResult<Visit>> call({
    required String title,
    required int clientId,
    required DateTime scheduledAt,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) async {
    final scheduled = ScheduledAt.create(scheduledAt, now: _now());
    if (scheduled is Fail<ScheduledAt>) {
      return Fail<Visit>(scheduled.code, scheduled.message);
    }
    final draft = Visit.draft(
      title: title,
      clientId: clientId,
      technicianName: _session.currentUser.name,
      scheduledAt: (scheduled as Ok<ScheduledAt>).value,
      checklist: checklist,
      notes: notes,
    );
    if (draft is Fail<Visit>) {
      return draft;
    }
    if (await _clients.findClientById(clientId) == null) {
      return const Fail(ClientFailureCodes.notFound, 'Cliente nao encontrado.');
    }
    return Ok(await _visits.saveVisit((draft as Ok<Visit>).value));
  }
}

/// Inicia uma visita agendada.
class StartVisitCommand {
  /// Cria o command sobre [visits].
  const StartVisitCommand(this._visits);

  final IVisitRepository _visits;

  /// Marca a visita como em andamento.
  Future<IResult<Visit>> call(int visitId) async {
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
      await _visits.saveVisit(visit.withStatus(EVisitStatus.inProgress)),
    );
  }
}

/// Conclui uma visita em andamento (marca o checklist inteiro).
class CompleteVisitCommand {
  /// Cria o command sobre [visits].
  const CompleteVisitCommand(this._visits);

  final IVisitRepository _visits;

  /// Conclui a visita e marca todos os itens do checklist.
  Future<IResult<Visit>> call(int visitId) async {
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
      EVisitStatus.completed,
    );
    return Ok(await _visits.saveVisit(completed));
  }
}

/// Marca ou desmarca um item do checklist.
class ToggleChecklistItemCommand {
  /// Cria o command sobre [visits].
  const ToggleChecklistItemCommand(this._visits);

  final IVisitRepository _visits;

  /// Inverte o item [index] do checklist da visita.
  Future<IResult<Visit>> call(int visitId, int index) async {
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

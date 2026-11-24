/// Fachada de casos de uso do app de visitas (`IVisitUseCases`).
///
/// SRP: agregar o ciclo da visita e a leitura de clientes num contrato unico
/// injetavel. NAO faz: regra de negocio (vive nos commands) nem I/O.
///
/// Patterns: Facade de UseCases (CQRS sem Mediator).
/// Dependencias: commands, queries, ports e sessao (puro).
library;

import '../../../core/result.dart';
import '../../clients/domain/.index.dart';
import '../../session/.index.dart';
import '../commands/visit_commands.dart';
import '../domain/.index.dart';
import 'list_visits/list_visits_query.dart';
import 'list_visits/visit_row.dart';

/// Contrato unico consumido pelo controller de visitas.
abstract interface class IVisitUseCases {
  /// Usuario da sessao (tecnico responsavel pelas visitas criadas).
  SessionUser get currentUser;

  /// Agenda uma visita no nome do usuario da sessao.
  Future<IResult<Visit>> scheduleVisit({
    required String title,
    required int clientId,
    required DateTime scheduledAt,
    List<ChecklistItem> checklist,
    String notes,
  });

  /// Inicia uma visita agendada.
  Future<IResult<Visit>> startVisit(int visitId);

  /// Conclui uma visita em andamento.
  Future<IResult<Visit>> completeVisit(int visitId);

  /// Marca ou desmarca um item do checklist.
  Future<IResult<Visit>> toggleChecklistItem(int visitId, int index);

  /// Lista as visitas com cliente, tecnico e progresso.
  Future<List<VisitRow>> listVisits({EVisitStatus? status, DateTime? day});

  /// Lista os clientes (usado pelo formulario de agendamento).
  Future<List<Client>> listClients();
}

/// Implementacao padrao compondo commands e queries.
class DefaultVisitUseCases implements IVisitUseCases {
  /// Monta a fachada sobre [visits], [clients] e [session].
  DefaultVisitUseCases({
    required IVisitRepository visits,
    required IClientRepository clients,
    required ISessionProvider session,
    DateTime Function()? now,
  }) : _listQuery = ListVisitsQuery(visits, clients),
       _schedule = ScheduleVisitCommand(visits, clients, session, now: now),
       _start = StartVisitCommand(visits),
       _complete = CompleteVisitCommand(visits),
       _toggle = ToggleChecklistItemCommand(visits),
       _clients = clients,
       _session = session;

  final ListVisitsQuery _listQuery;
  final ScheduleVisitCommand _schedule;
  final StartVisitCommand _start;
  final CompleteVisitCommand _complete;
  final ToggleChecklistItemCommand _toggle;
  final IClientRepository _clients;
  final ISessionProvider _session;

  @override
  SessionUser get currentUser => _session.currentUser;

  @override
  Future<IResult<Visit>> scheduleVisit({
    required String title,
    required int clientId,
    required DateTime scheduledAt,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) => _schedule(
    title: title,
    clientId: clientId,
    scheduledAt: scheduledAt,
    checklist: checklist,
    notes: notes,
  );

  @override
  Future<IResult<Visit>> startVisit(int visitId) => _start(visitId);

  @override
  Future<IResult<Visit>> completeVisit(int visitId) => _complete(visitId);

  @override
  Future<IResult<Visit>> toggleChecklistItem(int visitId, int index) =>
      _toggle(visitId, index);

  @override
  Future<List<VisitRow>> listVisits({EVisitStatus? status, DateTime? day}) =>
      _listQuery(status: status, day: day);

  @override
  Future<List<Client>> listClients() => _clients.listClients();
}

/// Fachada de casos de uso do app de visitas (`VisitUseCases`).
///
/// SRP: agregar os casos de uso num contrato unico injetavel. NAO faz:
/// regra de negocio (vive nos commands) nem I/O.
///
/// Patterns: Facade de UseCases (CQRS sem Mediator).
/// Dependencias: commands, queries e ports (puro).
library;

import '../../../core/result.dart';
import '../commands/visit_commands.dart';
import '../domain/.index.dart';
import 'list_visits/list_visits_query.dart';
import 'list_visits/visit_row.dart';

/// Contrato unico consumido pelo controller (1 dependencia).
abstract interface class VisitUseCases {
  /// Agenda uma visita.
  Future<Result<Visit>> scheduleVisit({
    required String title,
    required int clientId,
    required int technicianId,
    required DateTime scheduledAt,
    List<ChecklistItem> checklist,
    String notes,
  });

  /// Inicia uma visita agendada.
  Future<Result<Visit>> startVisit(int visitId);

  /// Conclui uma visita em andamento.
  Future<Result<Visit>> completeVisit(int visitId);

  /// Marca ou desmarca um item do checklist.
  Future<Result<Visit>> toggleChecklistItem(int visitId, int index);

  /// Lista as visitas com cliente, tecnico e progresso.
  Future<List<VisitRow>> listVisits({VisitStatus? status, DateTime? day});

  /// Lista os clientes cadastrados.
  Future<List<Client>> listClients();

  /// Lista os tecnicos cadastrados.
  Future<List<Technician>> listTechnicians();

  /// Cadastra um cliente.
  Future<Result<Client>> createClient({
    required String name,
    required String phone,
    String address,
  });

  /// Cadastra um tecnico.
  Future<Result<Technician>> createTechnician({
    required String name,
    required String specialty,
  });
}

/// Implementacao padrao compondo commands e queries.
class DefaultVisitUseCases implements VisitUseCases {
  /// Monta a fachada sobre os repositorios [visits], [clients] e [technicians].
  DefaultVisitUseCases({
    required VisitRepository visits,
    required ClientRepository clients,
    required TechnicianRepository technicians,
    DateTime Function()? now,
  }) : _listQuery = ListVisitsQuery(visits, clients, technicians),
       _schedule = ScheduleVisitCommand(visits, clients, technicians, now: now),
       _start = StartVisitCommand(visits),
       _complete = CompleteVisitCommand(visits),
       _toggle = ToggleChecklistItemCommand(visits),
       _clients = clients,
       _technicians = technicians;

  final ListVisitsQuery _listQuery;
  final ScheduleVisitCommand _schedule;
  final StartVisitCommand _start;
  final CompleteVisitCommand _complete;
  final ToggleChecklistItemCommand _toggle;
  final ClientRepository _clients;
  final TechnicianRepository _technicians;

  @override
  Future<Result<Visit>> scheduleVisit({
    required String title,
    required int clientId,
    required int technicianId,
    required DateTime scheduledAt,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) => _schedule(
    title: title,
    clientId: clientId,
    technicianId: technicianId,
    scheduledAt: scheduledAt,
    checklist: checklist,
    notes: notes,
  );

  @override
  Future<Result<Visit>> startVisit(int visitId) => _start(visitId);

  @override
  Future<Result<Visit>> completeVisit(int visitId) => _complete(visitId);

  @override
  Future<Result<Visit>> toggleChecklistItem(int visitId, int index) =>
      _toggle(visitId, index);

  @override
  Future<List<VisitRow>> listVisits({VisitStatus? status, DateTime? day}) =>
      _listQuery(status: status, day: day);

  @override
  Future<List<Client>> listClients() => _clients.listClients();

  @override
  Future<List<Technician>> listTechnicians() => _technicians.listTechnicians();

  @override
  Future<Result<Client>> createClient({
    required String name,
    required String phone,
    String address = '',
  }) async {
    final client = Client.create(name: name, phone: phone, address: address);
    if (client is Fail<Client>) {
      return client;
    }
    return Ok(await _clients.saveClient((client as Ok<Client>).value));
  }

  @override
  Future<Result<Technician>> createTechnician({
    required String name,
    required String specialty,
  }) async {
    final technician = Technician.create(name: name, specialty: specialty);
    if (technician is Fail<Technician>) {
      return technician;
    }
    return Ok(
      await _technicians.saveTechnician((technician as Ok<Technician>).value),
    );
  }
}

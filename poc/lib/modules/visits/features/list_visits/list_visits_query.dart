/// Query de listagem de visitas com join (`ListVisitsQuery`).
///
/// SRP: ler as visitas e resolver nome do cliente, do tecnico e progresso.
/// NAO faz: mutar estado nem validar entrada.
///
/// Patterns: Query de CQRS leve (leitura com join, sem entidades pesadas).
/// Dependencias: ports dos tres agregados (puro).
library;

import '../../domain/.index.dart';
import '../list_visits/visit_row.dart';

/// Query de listagem, opcionalmente filtrada por [status].
class ListVisitsQuery {
  /// Cria a query sobre os repositorios [visits], [clients] e [technicians].
  const ListVisitsQuery(this._visits, this._clients, this._technicians);

  final VisitRepository _visits;
  final ClientRepository _clients;
  final TechnicianRepository _technicians;

  /// Lista as visitas resolvendo os nomes; [status] e [day] filtram quando
  /// informados, e o resultado sai ordenado por data agendada.
  Future<List<VisitRow>> call({VisitStatus? status, DateTime? day}) async {
    final visits = await _visits.listVisits();
    final clients = await _clients.listClients();
    final technicians = await _technicians.listTechnicians();
    final clientNames = {for (final client in clients) client.id: client.name};
    final technicianNames = {
      for (final technician in technicians) technician.id: technician.name,
    };
    final filtered = [
      for (final visit in visits)
        if (status == null || visit.status == status)
          if (day == null || _sameDay(visit.scheduledAt.value, day)) visit,
    ];
    filtered.sort((a, b) => a.scheduledAt.value.compareTo(b.scheduledAt.value));
    return [
      for (final visit in filtered)
        VisitRow(
          id: visit.id,
          title: visit.title.value,
          status: visit.status.wire,
          clientName: clientNames[visit.clientId] ?? 'Cliente removido',
          technicianName:
              technicianNames[visit.technicianId] ?? 'Tecnico removido',
          progress: visit.progress,
          scheduledAt: visit.scheduledAt.value,
        ),
    ];
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

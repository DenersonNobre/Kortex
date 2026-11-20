/// Query de listagem de visitas com join de cliente (`ListVisitsQuery`).
///
/// SRP: ler as visitas e resolver nome do cliente e progresso.
/// NAO faz: mutar estado nem validar entrada.
///
/// Patterns: Query de CQRS leve (leitura com join, sem entidades pesadas).
/// Dependencias: ports de visitas e clientes (puro).
library;

import '../../../clients/domain/.index.dart';
import '../../domain/.index.dart';
import 'visit_row.dart';

/// Query de listagem, opcionalmente filtrada por [status] e por [day].
class ListVisitsQuery {
  /// Cria a query sobre os repositorios [visits] e [clients].
  const ListVisitsQuery(this._visits, this._clients);

  final VisitRepository _visits;
  final ClientRepository _clients;

  /// Lista as visitas resolvendo os nomes; [status] e [day] filtram quando
  /// informados, e o resultado sai ordenado por data agendada.
  Future<List<VisitRow>> call({VisitStatus? status, DateTime? day}) async {
    final visits = await _visits.listVisits();
    final clients = await _clients.listClients();
    final clientNames = {for (final client in clients) client.id: client.name};
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
          technicianName: visit.technicianName,
          progress: visit.progress,
          scheduledAt: visit.scheduledAt.value,
        ),
    ];
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Lista de visitas com status, cliente, tecnico e progresso.
///
/// SRP: renderizar cada linha e disparar as acoes da visita.
/// NAO faz: carregar dados nem manter estado proprio.
///
/// Patterns: `StatelessWidget` puro (a observacao vive na pagina).
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';

import '../../domain/.index.dart';
import '../../features/.index.dart';
import '../visits_controller.dart';

/// Lista de visitas da POC.
class VisitsList extends StatelessWidget {
  /// Cria a lista ligada ao [controller].
  const VisitsList({super.key, required this.controller});

  /// Controller dono das acoes.
  final VisitsController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.visits.state.value.valueOrNull ?? const [];
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Nenhuma visita'),
      );
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, index) =>
          _VisitTile(controller: controller, row: rows[index]),
    );
  }
}

/// Linha de uma visita com acoes por status.
class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.controller, required this.row});

  final VisitsController controller;
  final VisitRow row;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('visit-${row.id}'),
      title: Text(row.title),
      subtitle: Text('${row.clientName} · ${row.technicianName}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${(row.progress * 100).round()}%'),
          const SizedBox(width: 8),
          if (row.status == EVisitStatus.scheduled.wire)
            IconButton(
              key: Key('visit-start-${row.id}'),
              tooltip: 'Iniciar',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => controller.startVisit(row.id),
            ),
          if (row.status == EVisitStatus.inProgress.wire)
            IconButton(
              key: Key('visit-complete-${row.id}'),
              tooltip: 'Concluir',
              icon: const Icon(Icons.check),
              onPressed: () => controller.completeVisit(row.id),
            ),
        ],
      ),
    );
  }
}

/// Pagina de Agenda: visitas do dia selecionado.
///
/// SRP: compor o seletor de dias e a lista do dia, reagindo ao controller.
/// NAO faz: estado de negocio (papel do controller).
///
/// Patterns: `IKortexPage` + `KortexWatch` + `switch` exaustivo de estado.
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../features/.index.dart';
import 'agenda_controller.dart';

/// Tela de agenda diaria.
class AgendaPage extends IKortexPage<AgendaController> {
  /// Cria a pagina de agenda.
  const AgendaPage({super.key});

  @override
  Widget buildPage(BuildContext context, AgendaController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DaySelector(controller: controller),
          Expanded(child: _AgendaBody(controller: controller)),
        ],
      ),
    );
  }
}

/// Seletor dos proximos dias (7 dias a partir do dia selecionado).
class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.controller});

  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final selected = controller.selectedDay.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (var offset = 0; offset < 7; offset++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('agenda-day-${_offset(selected, offset)}'),
                    label: Text(_label(selected, offset)),
                    selected: offset == 0,
                    showCheckmark: false,
                    onSelected: (_) => controller.selectDay(
                      selected.add(Duration(days: offset)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _offset(DateTime base, int offset) =>
      '${base.add(Duration(days: offset)).day}';

  static String _label(DateTime base, int offset) =>
      '${base.add(Duration(days: offset)).day}';
}

/// Lista das visitas do dia.
class _AgendaBody extends StatelessWidget {
  const _AgendaBody({required this.controller});

  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final state = controller.agenda.state.value;
        return switch (state) {
          KortexAsyncLoading<List<VisitRow>>() => const Center(
            child: CircularProgressIndicator(),
          ),
          KortexAsyncError<List<VisitRow>>() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Falha ao carregar a agenda'),
                TextButton(
                  key: const Key('agenda-retry'),
                  onPressed: controller.refresh,
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
          KortexAsyncData<List<VisitRow>>(value: final rows) =>
            rows.isEmpty
                ? const Center(child: Text('Nenhuma visita neste dia'))
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final time = row.scheduledAt;
                      return ListTile(
                        key: Key('agenda-visit-${row.id}'),
                        leading: Text(
                          '${time.hour.toString().padLeft(2, '0')}:'
                          '${time.minute.toString().padLeft(2, '0')}',
                        ),
                        title: Text(row.title),
                        subtitle: Text(
                          '${row.clientName} · ${row.technicianName}',
                        ),
                      );
                    },
                  ),
        };
      },
    );
  }
}

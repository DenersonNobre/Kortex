/// Pagina de Agenda: grade mensal de cards e detalhe do dia selecionado.
///
/// SRP: compor os cards dos dias do mes e, ao clicar em um dia, virar a
/// pagina para mostrar os compromissos agendados daquele dia.
/// NAO faz: estado de negocio (papel do controller).
///
/// Patterns: `IKortexPage` + `KortexWatch` + `AnimatedSwitcher` + `switch`.
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../features/.index.dart';
import 'agenda_controller.dart';

/// Tela de agenda mensal com detalhe diario.
class AgendaPage extends IKortexPage<AgendaController> {
  /// Cria a pagina de agenda.
  const AgendaPage({super.key});

  @override
  Widget buildPage(BuildContext context, AgendaController controller) {
    return KortexWatch(
      builder: (context, child) {
        final showingDetail = controller.showingDayDetail.value;
        final selected = controller.selectedDay.value;
        return Scaffold(
          appBar: AppBar(
            leading: showingDetail
                ? IconButton(
                    key: const Key('agenda-back'),
                    tooltip: 'Voltar para o mes',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: controller.backToMonth,
                  )
                : null,
            title: Text(
              showingDetail ? 'Agenda — ${_formatDay(selected)}' : 'Agenda',
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: showingDetail
                ? _AgendaBody(
                    key: const ValueKey('agenda-detail'),
                    controller: controller,
                  )
                : _MonthScheduleGrid(
                    key: const ValueKey('agenda-month'),
                    controller: controller,
                  ),
          ),
        );
      },
    );
  }

  static String _formatDay(DateTime day) =>
      '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
}

/// Grade com os cards dos dias do mes focado.
class _MonthScheduleGrid extends StatelessWidget {
  const _MonthScheduleGrid({super.key, required this.controller});

  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final month = controller.focusedMonth.value;
        final selected = controller.selectedDay.value;
        final today = controller.today;
        final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
        final scheme = Theme.of(context).colorScheme;
        final counts = switch (controller.monthCounts.state.value) {
          KortexAsyncData<Map<int, int>>(value: final map) => map,
          _ => const <int, int>{},
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('agenda-prev-month'),
                    tooltip: 'Mes anterior',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: controller.previousMonth,
                  ),
                  Text(
                    '${_monthNames[month.month - 1]} ${month.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    key: const Key('agenda-next-month'),
                    tooltip: 'Proximo mes',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: controller.nextMonth,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = DateTime(month.year, month.month, index + 1);
                  final isToday = DateUtils.isSameDay(day, today);
                  final isSelected = DateUtils.isSameDay(day, selected);
                  final visitCount = counts[day.day] ?? 0;
                  final hasVisits = visitCount > 0;
                  return Card(
                    key: Key('agenda-day-${day.day}'),
                    elevation: hasVisits ? 3 : 0,
                    color: hasVisits
                        ? scheme.tertiaryContainer
                        : isSelected
                        ? scheme.primaryContainer
                        : isToday
                        ? scheme.secondaryContainer
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: hasVisits
                          ? BorderSide(color: scheme.tertiary, width: 1.5)
                          : BorderSide.none,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => controller.selectDay(day),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isToday || isSelected || hasVisits
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                          if (hasVisits)
                            Container(
                              key: Key('agenda-day-badge-${day.day}'),
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.tertiary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$visitCount',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: scheme.onTertiary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
}

/// Lista das visitas do dia selecionado.
class _AgendaBody extends StatelessWidget {
  const _AgendaBody({super.key, required this.controller});

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
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          KortexAsyncData<List<VisitRow>>(value: final rows) =>
            rows.isEmpty
                ? const Center(child: Text('Nenhuma visita neste dia'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final row = rows[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(row.title),
                          subtitle: Text(row.clientName),
                        ),
                      );
                    },
                  ),
        };
      },
    );
  }
}

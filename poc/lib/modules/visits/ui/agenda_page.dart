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
        final grouped = switch (controller.monthVisits.state.value) {
          KortexAsyncData<Map<int, List<VisitRow>>>(value: final map) => map,
          _ => const <int, List<VisitRow>>{},
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
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = DateTime(month.year, month.month, index + 1);
                  final dayVisits = grouped[day.day] ?? const <VisitRow>[];
                  return _DayScheduleCard(
                    day: day,
                    isToday: DateUtils.isSameDay(day, today),
                    isSelected: DateUtils.isSameDay(day, selected),
                    visits: dayVisits,
                    scheme: scheme,
                    onTap: () => controller.selectDay(day),
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

/// Card estilizado de um dia do mes (header, micro-lista e rodape).
class _DayScheduleCard extends StatelessWidget {
  const _DayScheduleCard({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.visits,
    required this.scheme,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final List<VisitRow> visits;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasVisits = visits.isNotEmpty;
    final headerColor = hasVisits
        ? scheme.tertiary
        : isToday
        ? scheme.primary
        : isSelected
        ? scheme.secondary
        : scheme.surfaceContainerHighest;
    final headerTextColor = hasVisits
        ? scheme.onTertiary
        : isToday
        ? scheme.onPrimary
        : isSelected
        ? scheme.onSecondary
        : scheme.onSurfaceVariant;
    final cardColor = hasVisits
        ? scheme.tertiaryContainer.withValues(alpha: 0.45)
        : isToday
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : null;

    return Card(
      key: Key('agenda-day-${day.day}'),
      elevation: hasVisits ? 3 : 0.5,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasVisits
              ? scheme.tertiary
              : isToday
              ? scheme.primary
              : scheme.outlineVariant,
          width: hasVisits || isToday ? 1.5 : 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: headerColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${day.day} • ${_weekdays[day.weekday - 1]}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: headerTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    hasVisits
                        ? Icons.event_available
                        : isToday
                        ? Icons.today
                        : Icons.calendar_today_outlined,
                    size: 14,
                    color: headerTextColor,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: hasVisits
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final row in visits.take(2))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.build_circle_outlined,
                                    size: 12,
                                    color: scheme.tertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      row.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Icon(
                          Icons.event_busy_outlined,
                          size: 18,
                          color: scheme.outlineVariant,
                        ),
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: hasVisits
                  ? scheme.tertiary.withValues(alpha: 0.14)
                  : scheme.surfaceContainerLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    hasVisits
                        ? Icons.assignment_turned_in_outlined
                        : Icons.remove_circle_outline,
                    size: 12,
                    color: hasVisits ? scheme.tertiary : scheme.outline,
                  ),
                  Text(
                    hasVisits ? '${visits.length} ativ.' : 'Livre',
                    key: hasVisits ? Key('agenda-day-badge-${day.day}') : null,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: hasVisits ? scheme.tertiary : scheme.outline,
                      fontWeight: hasVisits
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
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

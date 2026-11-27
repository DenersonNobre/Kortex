/// Controller da Agenda (calendario mensal + visitas por dia).
///
/// SRP: expor o mes focado, o dia selecionado, o modo de visualizacao
/// (grade do mes vs detalhe do dia) e a lista de visitas daquele dia.
/// NAO faz: agendar (papel da area Visitas) nem UI.
///
/// Patterns: `IKortexController` + `KortexResource` por dia selecionado.
/// Dependencias: `kortex` + camada `features` do modulo de visitas.
library;

import 'package:kortex/kortex.dart';
import 'package:kortex_lib/kortex_lib.dart' show LogManager;

import '../features/.index.dart';

/// Controller da tela de Agenda.
class AgendaController extends IKortexController {
  /// Cria a agenda com o dia inicial em [today] (injetavel para testes).
  AgendaController(this._useCases, {DateTime? today})
    : _today = _dayOnly(today ?? DateTime.now()),
      selectedDay = KortexSignal(_dayOnly(today ?? DateTime.now())),
      focusedMonth = KortexSignal(
        DateTime(
          (today ?? DateTime.now()).year,
          (today ?? DateTime.now()).month,
        ),
      ) {
    LogManager.scope('Lifecycle').debug('$runtimeType criado');
    agenda = autoDispose(
      kortexResource<List<VisitRow>>(
        () => _useCases.listVisits(day: selectedDay.peek()),
        immediate: false,
      ),
    );
    monthVisits = autoDispose(
      kortexResource<Map<int, List<VisitRow>>>(
        _loadMonthVisits,
        immediate: true,
      ),
    );
    autoDispose(selectedDay);
    autoDispose(focusedMonth);
    autoDispose(showingDayDetail);
  }

  final IVisitUseCases _useCases;
  final DateTime _today;

  /// Dia de referencia ("hoje").
  DateTime get today => _today;

  /// Dia selecionado (meia-noite do dia).
  final KortexSignal<DateTime> selectedDay;

  /// Mes atualmente exibido na grade de cards.
  final KortexSignal<DateTime> focusedMonth;

  /// Quando `true`, exibe os compromissos do [selectedDay]; quando `false`,
  /// exibe os cards dos dias do mes.
  final KortexSignal<bool> showingDayDetail = KortexSignal(false);

  /// Visitas do dia selecionado.
  late final KortexResource<List<VisitRow>> agenda;

  /// Visitas agrupadas por dia do [focusedMonth].
  late final KortexResource<Map<int, List<VisitRow>>> monthVisits;

  /// Recarrega as visitas do dia selecionado e os dados do mes.
  Future<void> refresh() async {
    await Future.wait([agenda.refresh(), monthVisits.refresh()]);
  }

  /// Seleciona [day], abre o detalhe do dia e carrega os compromissos.
  Future<void> selectDay(DateTime day) async {
    selectedDay.value = _dayOnly(day);
    showingDayDetail.value = true;
    await refresh();
  }

  /// Volta para a grade de cards do mes.
  void backToMonth() {
    showingDayDetail.value = false;
    monthVisits.refresh();
  }

  /// Navega para o mes anterior.
  void previousMonth() {
    final m = focusedMonth.peek();
    focusedMonth.value = DateTime(m.year, m.month - 1);
    monthVisits.refresh();
  }

  /// Navega para o proximo mes.
  void nextMonth() {
    final m = focusedMonth.peek();
    focusedMonth.value = DateTime(m.year, m.month + 1);
    monthVisits.refresh();
  }

  Future<Map<int, List<VisitRow>>> _loadMonthVisits() async {
    final month = focusedMonth.peek();
    final all = await _useCases.listVisits();
    final grouped = <int, List<VisitRow>>{};
    for (final row in all) {
      final d = row.scheduledAt;
      if (d.year == month.year && d.month == month.month) {
        (grouped[d.day] ??= []).add(row);
      }
    }
    return grouped;
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

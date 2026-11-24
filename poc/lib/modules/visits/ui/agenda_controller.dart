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
    agenda = autoDispose(
      kortexResource<List<VisitRow>>(
        () => _useCases.listVisits(day: selectedDay.peek()),
        immediate: false,
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

  /// Recarrega as visitas do dia selecionado.
  Future<void> refresh() => agenda.refresh();

  /// Seleciona [day], abre o detalhe do dia e carrega os compromissos.
  Future<void> selectDay(DateTime day) async {
    selectedDay.value = _dayOnly(day);
    showingDayDetail.value = true;
    await refresh();
  }

  /// Volta para a grade de cards do mes.
  void backToMonth() {
    showingDayDetail.value = false;
  }

  /// Navega para o mes anterior.
  void previousMonth() {
    final m = focusedMonth.peek();
    focusedMonth.value = DateTime(m.year, m.month - 1);
  }

  /// Navega para o proximo mes.
  void nextMonth() {
    final m = focusedMonth.peek();
    focusedMonth.value = DateTime(m.year, m.month + 1);
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

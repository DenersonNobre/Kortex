/// Controller da Agenda (visitas por dia).
///
/// SRP: expor o dia selecionado e a lista de visitas daquele dia.
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
    : selectedDay = KortexSignal(_dayOnly(today ?? DateTime.now())) {
    agenda = autoDispose(
      kortexResource<List<VisitRow>>(
        () => _useCases.listVisits(day: selectedDay.peek()),
        immediate: false,
      ),
    );
    autoDispose(selectedDay);
  }

  final VisitUseCases _useCases;

  /// Dia selecionado (meia-noite do dia).
  final KortexSignal<DateTime> selectedDay;

  /// Visitas do dia selecionado.
  late final KortexResource<List<VisitRow>> agenda;

  /// Recarrega as visitas do dia selecionado.
  Future<void> refresh() => agenda.refresh();

  /// Seleciona [day] e recarrega.
  Future<void> selectDay(DateTime day) async {
    selectedDay.value = _dayOnly(day);
    await refresh();
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

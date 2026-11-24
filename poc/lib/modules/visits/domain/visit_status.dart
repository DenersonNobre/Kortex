/// Status da visita (`EVisitStatus`).
///
/// SRP: representar o ciclo de vida da visita e as transicoes validas.
/// NAO faz: agendar, persistir nem notificar.
///
/// Patterns: Enum com fabrica `parse` que devolve `IResult`.
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'visit_failures.dart';

/// Situacao possivel de uma visita tecnica.
enum EVisitStatus {
  /// Agendada, ainda nao iniciada.
  scheduled('scheduled'),

  /// Em andamento, checklist em execucao.
  inProgress('in_progress'),

  /// Concluida.
  completed('completed');

  const EVisitStatus(this.wire);

  /// Texto usado na serializacao (filtros e persistencia).
  final String wire;

  /// Verdadeiro quando a visita pode ser iniciada.
  bool get canStart => this == EVisitStatus.scheduled;

  /// Verdadeiro quando a visita pode ser concluida.
  bool get canComplete => this == EVisitStatus.inProgress;

  /// Interpreta [raw]; devolve `Fail` para valor desconhecido.
  static IResult<EVisitStatus> parse(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final status in EVisitStatus.values) {
      if (status.wire == normalized) {
        return Ok(status);
      }
    }
    return const Fail(
      VisitFailureCodes.statusInvalid,
      'Status de visita desconhecido.',
    );
  }
}

/// Status da visita (`VisitStatus`).
///
/// SRP: representar o ciclo de vida da visita e as transicoes validas.
/// NAO faz: agendar, persistir nem notificar.
///
/// Patterns: Enum com fabrica `parse` que devolve `Result`.
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'visit_failures.dart';

/// Situacao possivel de uma visita tecnica.
enum VisitStatus {
  /// Agendada, ainda nao iniciada.
  scheduled('scheduled'),

  /// Em andamento, checklist em execucao.
  inProgress('in_progress'),

  /// Concluida.
  completed('completed');

  const VisitStatus(this.wire);

  /// Texto usado na serializacao (filtros e persistencia).
  final String wire;

  /// Verdadeiro quando a visita pode ser iniciada.
  bool get canStart => this == VisitStatus.scheduled;

  /// Verdadeiro quando a visita pode ser concluida.
  bool get canComplete => this == VisitStatus.inProgress;

  /// Interpreta [raw]; devolve `Fail` para valor desconhecido.
  static Result<VisitStatus> parse(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final status in VisitStatus.values) {
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

/// Data e hora agendadas da visita (`ScheduledAt`).
///
/// SRP: garantir que a visita seja agendada para o futuro, normalizando ao
/// minuto (segundos e milissegundos zerados). NAO faz: formatacao para a UI
/// nem fuso horario (papel da apresentacao).
///
/// Patterns: Value Object com fabrica que devolve `IResult` e `now` injetado
/// (dominio deterministico, sem `DateTime.now()`).
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'visit_failures.dart';

/// Instante de atendimento sempre no futuro (construcao so via `create`).
final class ScheduledAt {
  const ScheduledAt._(this.value);

  /// Instante normalizado ao minuto.
  final DateTime value;

  /// Valida [raw] contra [now]; devolve `Ok` ou `Fail` com codigo estavel.
  static AppResult<ScheduledAt> create(DateTime raw, {required DateTime now}) {
    final normalized = DateTime(
      raw.year,
      raw.month,
      raw.day,
      raw.hour,
      raw.minute,
    );
    final reference = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    if (!normalized.isAfter(reference)) {
      return const Failure(AppFailure(
        VisitFailureCodes.scheduledInPast,
        'Agende a visita para uma data futura.',
      ));
    }
    return Success(ScheduledAt._(normalized));
  }
}

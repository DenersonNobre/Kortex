/// Titulo validado da visita (`VisitTitle`).
///
/// SRP: garantir o invariante (nao-vazio, ate `maxLength`, normalizado).
/// NAO faz: persistencia nem UI.
///
/// Patterns: Value Object com fabrica que devolve `IResult`.
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'visit_failures.dart';

/// Titulo de visita sempre valido (construcao so via `create`).
final class VisitTitle {
  const VisitTitle._(this.value);

  /// Tamanho maximo aceito.
  static const int maxLength = 140;

  /// Valor normalizado (sem espacos nas bordas).
  final String value;

  /// Valida [raw] e devolve `Ok` ou `Fail` com codigo estavel.
  static AppResult<VisitTitle> create(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        AppFailure(
          VisitFailureCodes.titleEmpty,
          'Titulo da visita nao pode ser vazio.',
        ),
      );
    }
    if (trimmed.length > maxLength) {
      return const Failure(
        AppFailure(
          VisitFailureCodes.titleTooLong,
          'Titulo com mais de 140 caracteres.',
        ),
      );
    }
    return Success(VisitTitle._(trimmed));
  }
}

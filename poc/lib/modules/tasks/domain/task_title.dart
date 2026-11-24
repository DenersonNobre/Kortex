/// Valor validado do título (`TaskTitle`).
///
/// SRP: garantir invariante (não-vazio, até `maxLength`, normalizado com
/// trim) na fronteira de criação. NÃO faz: persistência nem UI.
///
/// Patterns: Value Object com fábrica que devolve `IResult`.
/// Dependências: `shared/result.dart` + `task_failures.dart` (puro).
library;

import '../../../core/result.dart';
import 'task_failures.dart';

/// Título de task sempre válido (construção só via `create`).
final class TaskTitle {
  const TaskTitle._(this.value);

  /// Tamanho máximo aceito.
  static const int maxLength = 120;

  /// Valor normalizado (sem espaços nas bordas).
  final String value;

  /// Valida [raw] e devolve `Ok` ou `Fail` com código estável.
  static AppResult<TaskTitle> create(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failure(AppFailure(
        TaskFailureCodes.emptyTitle,
        'Título não pode ser vazio.',
      ));
    }
    if (trimmed.length > maxLength) {
      return const Failure(AppFailure(
        TaskFailureCodes.titleTooLong,
        'Título com mais de 120 caracteres.',
      ));
    }
    return Success(TaskTitle._(trimmed));
  }
}

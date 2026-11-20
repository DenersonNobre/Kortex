/// Códigos estáveis de falha do módulo de tasks.
///
/// SRP: centralizar os `code`s de `Fail` (nunca literais espalhados).
/// NÃO faz: mensagens (vão no `Fail.message` de cada sítio).
library;

/// Códigos de falha de negócio das tasks.
abstract final class TaskFailureCodes {
  /// Título vazio ou só espaços.
  static const emptyTitle = 'TASK_EMPTY_TITLE';

  /// Título acima de `TaskTitle.maxLength`.
  static const titleTooLong = 'TASK_TITLE_TOO_LONG';

  /// Id sem task correspondente.
  static const notFound = 'TASK_NOT_FOUND';
}

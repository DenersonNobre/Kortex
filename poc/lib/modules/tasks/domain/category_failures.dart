/// Códigos estáveis de falha de `Category`.
///
/// SRP: centralizar os `code`s de `Fail` do agregado categoria.
/// NÃO faz: mensagens (vão no `Fail.message` de cada sítio).
library;

/// Códigos de falha de negócio das categorias.
abstract final class CategoryFailureCodes {
  /// Nome vazio ou só espaços.
  static const emptyName = 'CATEGORY_EMPTY_NAME';

  /// Nome acima de `CategoryName.maxLength`.
  static const nameTooLong = 'CATEGORY_NAME_TOO_LONG';

  /// Cor fora do formato `#RRGGBB`.
  static const invalidColor = 'CATEGORY_INVALID_COLOR';

  /// Id sem categoria correspondente.
  static const notFound = 'CATEGORY_NOT_FOUND';

  /// Categoria referenciada por tasks (exclusão bloqueada).
  static const inUse = 'CATEGORY_IN_USE';
}

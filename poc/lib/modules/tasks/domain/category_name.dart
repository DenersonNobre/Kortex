/// Nome validado de categoria (`CategoryName`).
///
/// SRP: garantir invariante (não-vazio, até `maxLength`, normalizado).
/// NÃO faz: persistência nem UI.
///
/// Patterns: Value Object com fábrica que devolve `Result`.
/// Dependências: `shared/result.dart` + códigos (puro).
library;

import '../../../core/result.dart';
import 'category_failures.dart';

/// Nome de categoria sempre válido (construção só via `create`).
final class CategoryName {
  const CategoryName._(this.value);

  /// Tamanho máximo aceito.
  static const int maxLength = 60;

  /// Valor normalizado (sem espaços nas bordas).
  final String value;

  /// Valida [raw] e devolve `Ok` ou `Fail` com código estável.
  static Result<CategoryName> create(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Fail(
        CategoryFailureCodes.emptyName,
        'Nome da categoria não pode ser vazio.',
      );
    }
    if (trimmed.length > maxLength) {
      return const Fail(
        CategoryFailureCodes.nameTooLong,
        'Nome com mais de 60 caracteres.',
      );
    }
    return Ok(CategoryName._(trimmed));
  }
}

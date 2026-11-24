/// Cor hexadecimal validada (`CategoryColor`).
///
/// SRP: garantir o formato `#RRGGBB` na fronteira de criação.
/// NÃO faz: conversão para `Color` do Flutter (papel da presentation).
///
/// Patterns: Value Object com fábrica que devolve `IResult`.
/// Dependências: `shared/result.dart` + códigos (puro).
library;

import '../../../core/result.dart';
import 'category_failures.dart';

/// Cor sempre no formato `#RRGGBB` (construção só via `create`).
final class CategoryColor {
  const CategoryColor._(this.value);

  static final RegExp _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

  /// Valor normalizado no formato `#RRGGBB`.
  final String value;

  /// Valida [raw] e devolve `Ok` ou `Fail` com código estável.
  static IResult<CategoryColor> create(String raw) {
    final trimmed = raw.trim();
    if (!_hex.hasMatch(trimmed)) {
      return const Fail(
        CategoryFailureCodes.invalidColor,
        'Cor deve ser hexadecimal #RRGGBB.',
      );
    }
    return Ok(CategoryColor._(trimmed));
  }
}

/// Entidade imutável `Category` + fábrica validada (`draft`).
///
/// SRP: identidade (`id`), nome e cor validados. NÃO faz: validar texto
/// (papel dos VOs) nem persistir (papel do repositório).
///
/// Patterns: Entidade imutável + Factory que propaga o primeiro `Fail`.
/// Dependências: VOs + `shared/result.dart` (puro).
library;

import '../../../core/result.dart';
import 'category_color.dart';
import 'category_name.dart';

/// Categoria com `id` (`0` = transiente, ainda não persistida).
final class Category {
  /// Cria a categoria com [id], [name] e [color].
  const Category({required this.id, required this.name, required this.color});

  /// Identificador (`0` antes da primeira persistência).
  final int id;

  /// Nome sempre válido.
  final CategoryName name;

  /// Cor sempre no formato `#RRGGBB`.
  final CategoryColor color;

  /// Valida [rawName]/[rawColor] e devolve a transiente ou o `Fail`.
  static AppResult<Category> draft(String rawName, String rawColor) {
    final name = CategoryName.create(rawName);
    if (name is Failure<CategoryName, AppFailure>) {
      return Failure<Category, AppFailure>(AppFailure(name.code, name.message));
    }
    final color = CategoryColor.create(rawColor);
    if (color is Failure<CategoryColor, AppFailure>) {
      return Failure<Category, AppFailure>(
        AppFailure(color.code, color.message),
      );
    }
    return Success(
      Category(
        id: 0,
        name: (name as Success<CategoryName, AppFailure>).value,
        color: (color as Success<CategoryColor, AppFailure>).value,
      ),
    );
  }
}

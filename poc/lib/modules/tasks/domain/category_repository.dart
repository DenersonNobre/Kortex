/// Porta de persistência de categorias (`ICategoryRepository`).
///
/// SRP: contrato mínimo de CRUD síncrono para o agregado `Category`.
/// NÃO faz: validar regras (domínio) nem I/O real.
///
/// Patterns: Port explícita (ISP: só o que as features usam).
/// Dependências: apenas a entidade (puro, sem infra).
library;

import 'category.dart';

/// Contrato de persistência usado pelos commands de categoria.
abstract interface class ICategoryRepository {
  /// Lista todas ordenadas por `id`.
  List<Category> findAll();

  /// Busca por [id] ou `null` quando ausente.
  Category? findById(int id);

  /// Insere (gera `id` quando `0`) ou substitui pelo `id`.
  Category save(Category category);

  /// Remove por [id]; ausente é no-op.
  void deleteById(int id);
}

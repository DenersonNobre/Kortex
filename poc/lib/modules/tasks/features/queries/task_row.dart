/// Visão de leitura de task com categoria resolvida (`TaskRow`).
///
/// SRP: transportar para a UI o resultado do join task→categoria.
/// NÃO faz: validar, persistir nem observar.
///
/// Patterns: DTO imutável montado pela query.
/// Dependências: apenas `dart:core`.
library;

/// Linha da lista de tasks com o nome da categoria (quando houver).
final class TaskRow {
  /// Cria a view com os campos resolvidos pela query.
  const TaskRow({
    required this.id,
    required this.title,
    required this.done,
    this.categoryId,
    this.categoryName,
  });

  /// Identificador da task.
  final int id;

  /// Título já validado.
  final String title;

  /// Concluída ou não.
  final bool done;

  /// Categoria vinculada (`null` = sem categoria).
  final int? categoryId;

  /// Nome resolvido via join (`null` = sem categoria).
  final String? categoryName;
}

/// Representação imutável do resultado de uma busca paginada.
class PageResult<T> {
  /// Lista imutável contendo os itens desta página.
  final List<T> items;

  /// Ponto de partida (índice base zero) dos registros retornados.
  final int offset;

  /// Quantidade máxima de itens solicitada para a página.
  final int limit;

  /// Quantidade total de registros disponíveis na fonte de dados.
  final int total;

  /// Cria uma página com [items] encapsulados de forma não modificável.
  PageResult({
    required Iterable<T> items,
    required this.offset,
    required this.limit,
    required this.total,
  }) : items = List<T>.unmodifiable(items);

  /// Cria uma página vazia sem resultados.
  const PageResult.empty() : items = const [], offset = 0, limit = 0, total = 0;

  /// Retorna a quantidade de itens presentes nesta página específica.
  int get length => items.length;

  /// Indica se a página retornou sem nenhum item.
  bool get isEmpty => items.isEmpty;

  /// Indica se a página possui ao menos um item.
  bool get isNotEmpty => items.isNotEmpty;

  /// Indica se ainda existem páginas subsequentes a serem carregadas na fonte.
  bool get hasMore => offset + items.length < total;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PageResult<T>) return false;
    if (other.offset != offset ||
        other.limit != limit ||
        other.total != total ||
        other.items.length != items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (items[i] != other.items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(offset, limit, total, Object.hashAll(items));
}

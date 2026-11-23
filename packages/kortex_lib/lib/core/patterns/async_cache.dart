// Cache assíncrono com TTL: retorna o valor em cache enquanto o item não
// expira; [invalidate] descarta imediatamente.
//
// Atribuição: **idioma de cache com TTL (tooling)** — fora dos 23 GoF.

/// Cache assíncrono com TTL: [getOrLoad] retorna o valor em cache se o item
/// foi carregado dentro de [duration]; caso contrário executa [load] e
/// armazena. [invalidate] descarta o valor imediatamente.
class AsyncCache<T> {
  AsyncCache({
    required this.duration,
    required this.load,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration duration;
  final Future<T> Function() load;
  final DateTime Function() _clock;

  T? _valor;
  DateTime? _gravadoEm;
  bool _sujo = true;

  /// Retorna o valor em cache quando dentro do TTL; caso contrário executa
  /// [load], armazena e devolve o valor novo.
  Future<T> getOrLoad() async {
    final gravadoEm = _gravadoEm;
    if (!_sujo &&
        gravadoEm != null &&
        _clock().difference(gravadoEm) < duration) {
      return _valor as T;
    }
    final novo = await load();
    _valor = novo;
    _gravadoEm = _clock();
    _sujo = false;
    return novo;
  }

  /// Descarta o valor em cache e força novo carregamento no próximo accesso.
  void invalidate() {
    _valor = null;
    _gravadoEm = null;
    _sujo = true;
  }
}

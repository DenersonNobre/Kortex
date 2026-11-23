// Adia a criação de [instancia] até o primeiro acesso (GoF Proxy/Lazy).

/// Proxy preguiçoso: a [instancia] só é criada uma vez, no primeiro acesso à
/// [instancia]; acessos subsequentes devolvem a mesma referência.
class LazyProxy<T> {
  LazyProxy(this._factory);

  final T Function() _factory;
  T? _instancia;
  bool _criada = false;

  /// Instância criada sob demanda (uma única vez) pela factory.
  T get instancia {
    if (!_criada) {
      _instancia = _factory();
      _criada = true;
    }
    return _instancia as T;
  }
}

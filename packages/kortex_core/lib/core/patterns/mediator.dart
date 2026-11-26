// [GoF Mediator] (behavioral): encapsula como um conjunto de colegas
// interage - o [Mediator] centraliza o roteamento para que nenhum colega
// referencie outro diretamente.
//
// Suporta dois modos de mediacao:
// 1. Notificacao GoF classica: par (Remetente, Mensagem) unidirecional via [on] e [notify].
// 2. Requisicao/Resposta assincrona (Request-Response Dispatcher):
//    [send] despacha um [IRequest] para um handler registrado e devolve [Future<TResponse>].

/// Representa uma requisicao, comando ou query que produz uma resposta [TResponse].
abstract interface class IRequest<TResponse> {}

/// Manipulador orientado a objeto de uma requisicao [TRequest] que produz [TResponse].
abstract interface class IRequestHandler<
  TRequest extends IRequest<TResponse>,
  TResponse
> {
  Future<TResponse> handle(TRequest request);
}

/// Contrato do despachante/mediador para inversao de dependencia (DIP).
abstract interface class IMediator {
  /// Registra [handler] para uma [Mensagem] originada por qualquer instancia
  /// de [Remetente]; devolve o token que desfaz o registro.
  void Function() on<Remetente, Mensagem>(
    void Function(Mensagem message) handler,
  );

  /// Roteia [message] vinda de [Remetente] para os handlers do par registro.
  void notify<Remetente, Mensagem>(Mensagem message);

  /// Registra uma funcao [handler] para a requisicao [TRequest].
  ///
  /// O registro vale para o tipo concreto exato de [TRequest]: subclasses
  /// NÃO herdam o handler (ver [send]).
  void register<TRequest extends IRequest<TResponse>, TResponse>(
    Future<TResponse> Function(TRequest request) handler,
  );

  /// Registra um [IRequestHandler] orientado a objetos para a requisicao [TRequest].
  ///
  /// O registro vale para o tipo concreto exato de [TRequest]: subclasses
  /// NÃO herdam o handler (ver [send]).
  void registerHandler<TRequest extends IRequest<TResponse>, TResponse>(
    IRequestHandler<TRequest, TResponse> handler,
  );

  /// Desfaz o registro do handler de [TRequest].
  void unregister<TRequest extends IRequest<dynamic>>();

  /// Despacha [request] para o handler correspondente e devolve [TResponse].
  ///
  /// O roteamento é por tipo concreto exato (`request.runtimeType`): só o
  /// handler registrado para aquela classe concreta responde. Uma instância
  /// de subclasse NÃO dispara o handler da superclasse — cada requisição
  /// concreta precisa do próprio registro. Sem registro, lança [StateError].
  /// Este é o contrato da convenção `IRequest`/`IRequestHandler` (um handler
  /// por requisição concreta), não uma limitação a corrigir.
  Future<TResponse> send<TResponse>(IRequest<TResponse> request);

  /// Descarta todos os registros de notificacoes e requisicoes.
  void dispose();
}

/// Roteia mensagens e requisicoes entre colegas sem referencias mutuas (GoF Mediator).
class Mediator implements IMediator {
  final Map<(Type, Type), List<void Function(dynamic)>> _roteadores = {};
  final Map<Type, dynamic> _requestHandlers = {};

  @override
  void Function() on<Remetente, Mensagem>(
    void Function(Mensagem message) handler,
  ) {
    final lista = _roteadores.putIfAbsent((
      Remetente,
      Mensagem,
    ), () => <void Function(dynamic)>[]);
    void wrapper(dynamic m) => handler(m as Mensagem);
    lista.add(wrapper);
    return () => lista.remove(wrapper);
  }

  @override
  void notify<Remetente, Mensagem>(Mensagem message) {
    final lista = _roteadores[(Remetente, Mensagem)];
    if (lista == null) {
      return;
    }
    for (final handler in List.of(lista)) {
      handler(message);
    }
  }

  @override
  void register<TRequest extends IRequest<TResponse>, TResponse>(
    Future<TResponse> Function(TRequest request) handler,
  ) {
    _requestHandlers[TRequest] = handler;
  }

  @override
  void registerHandler<TRequest extends IRequest<TResponse>, TResponse>(
    IRequestHandler<TRequest, TResponse> handler,
  ) {
    _requestHandlers[TRequest] = (TRequest req) => handler.handle(req);
  }

  @override
  void unregister<TRequest extends IRequest<dynamic>>() {
    _requestHandlers.remove(TRequest);
  }

  @override
  Future<TResponse> send<TResponse>(IRequest<TResponse> request) async {
    final handler = _requestHandlers[request.runtimeType];
    if (handler == null) {
      throw StateError(
        'Nenhum handler registrado no Mediator para ${request.runtimeType}',
      );
    }
    return await (handler as Function)(request) as TResponse;
  }

  @override
  void dispose() {
    _roteadores.clear();
    _requestHandlers.clear();
  }
}

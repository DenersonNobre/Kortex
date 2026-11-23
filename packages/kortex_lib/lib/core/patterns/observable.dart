import 'dart:async';

// [GoF Observer] (behavioral) com valor corrente: um [Observable] guarda um
// valor e notifica quem assinar. É o complemento de estado do [EventBus] — o
// EventBus publica eventos sem valor corrente; o Observable expõe o valor para
// leitura imediata e reativa.
//
// SRP: guarda um valor e notifica mudanças. NÃO aplica lógica de domínio e NÃO
// conhece framework — o módulo `widgets` fornece o adaptador para o
// `ValueListenable` do Flutter.
//
// Dependências: nenhuma (Dart puro).

/// Token de assinatura em um [Observable].
///
/// Devolvido por [Observable.on], no mesmo papel do `StreamSubscription`
/// devolvido por [EventBus.on]. Preferir o token a [Observable.removeListener]
/// porque o cancelamento não depende da identidade da closure.
/// Assinatura viva: enquanto [isActive] for `true`, o assinante recebe as
/// mudanças de [value].
class ObservableToken<T> {
  ObservableToken._(this.observable, this._listener, [this._onCancel]);

  /// [Observable] de origem; exposto para leitura do valor corrente.
  final Observable<T> observable;

  final void Function(T value) _listener;

  /// Gancho de limpeza executado no máximo uma vez, em [cancel] ou quando o
  /// [Observable] de origem é descartado ([_invalidate]). Erros do gancho vão
  /// para a [Zone] corrente e nunca quebram o cancelamento/descarte.
  final void Function()? _onCancel;

  bool _isActive = true;

  /// Garante execução única do gancho, mesmo com `cancel()` + `dispose()`.
  bool _cancelHookRan = false;

  /// `true` enquanto a assinatura não foi cancelada nem invalidada por
  /// [Observable.dispose].
  bool get isActive => _isActive;

  /// Valor corrente do [Observable] de origem.
  T get value => observable.value;

  /// Cancela a assinatura. Idempotente.
  void cancel() {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    observable._removeToken(this);
    _runCancelHook();
  }

  void _notify(T value) {
    if (!_isActive) {
      return;
    }
    _listener(value);
  }

  void _invalidate() {
    _isActive = false;
    _runCancelHook();
  }

  void _runCancelHook() {
    if (_cancelHookRan) {
      return;
    }
    _cancelHookRan = true;
    try {
      _onCancel?.call();
    } catch (error, stackTrace) {
      Zone.current.handleUncaughtError(error, stackTrace);
    }
  }
}

/// Contêiner observável de um valor, com notificação aos assinantes.
///
/// Assinantes adicionados depois da última mudança leem o valor corrente em
/// [value] — diferente do [EventBus], que não faz replay. Use [on] para obter
/// um [ObservableToken] e cancelá-lo sem depender da identidade da closure.
class Observable<T> {
  Observable(T value) : _value = value;

  T _value;
  final List<ObservableToken<T>> _tokens = [];
  bool _disposed = false;

  /// Chave de [Zone] usada por rastreadores reativos externos (ex.: Synapx)
  /// para interceptar leituras de [value] sem estado global mutável.
  static final Object readTrackerZoneKey = Object();

  /// Valor corrente.
  T get value {
    (Zone.current[readTrackerZoneKey] as void Function(Observable<dynamic>)?)
        ?.call(this);
    return _value;
  }

  /// Substitui o valor e notifica os assinantes quando ele muda de fato.
  ///
  /// Após [dispose], a atribuição é ignorada.
  set value(T next) {
    if (_disposed || _value == next) {
      return;
    }
    _value = next;
    _notify();
  }

  /// Notifica os assinantes com o valor corrente, sem alterá-lo.
  ///
  /// Uso: tipos que encapsulam mutação interna (ex.: `SynapxList`) chamam [notify]
  /// após alterar o conteúdo referenciado por [value]. Após [dispose], é
  /// ignorado.
  void notify() => _notify();

  /// Assina [listener] para as próximas mudanças e devolve o token da
  /// assinatura. Opcionalmente registra [onCancel], executado no máximo uma
  /// vez quando o token é cancelado ou o [Observable] é descartado.
  ///
  /// Não há replay: [listener] só recebe mudanças posteriores a [on]. Assinar
  /// após [dispose] devolve um token já inativo.
  ObservableToken<T> on(
    void Function(T value) listener, {
    void Function()? onCancel,
  }) {
    final token = ObservableToken<T>._(this, listener, onCancel);
    if (_disposed) {
      token._invalidate();
      return token;
    }
    _tokens.add(token);
    return token;
  }

  /// Cancela a assinatura correspondente a [token].
  void removeListener(ObservableToken<T> token) => token.cancel();

  /// Descarta os assinantes e invalida os tokens pendentes.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final token in List<ObservableToken<T>>.of(_tokens)) {
      token._invalidate();
    }
    _tokens.clear();
  }

  void _removeToken(ObservableToken<T> token) => _tokens.remove(token);

  void _notify() {
    if (_disposed) {
      return;
    }
    for (final token in List<ObservableToken<T>>.of(_tokens)) {
      try {
        token._notify(_value);
      } catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
  }
}

/// Extensao fluente para criacao e encapsulamento de [Observable] a partir de qualquer valor.
extension ObservableBindExtension<T> on T {
  /// Envolve este valor em um [Observable<T>].
  Observable<T> get bind => Observable<T>(this);
}

/// Helper para criacao concisa de um [Observable<T?>] inicializado opcionalmente (padrao null).
Observable<T?> bindOf<T>([T? initial]) => Observable<T?>(initial);

/// Reação automática a sinais em Dart puro (`KortexEffect`).
///
/// SRP: reexecutar [efeito] quando dependências mudarem, com limpeza
/// (`onCleanup`), anti-rebote (`debounce`) e descarte explícito. NÃO faz:
/// guardar valor observável (não é nó) nem loteamento.
///
/// Patterns: Observer (folha) + Debounce via `Timer` de `dart:async`.
/// Dependências: `dart:async`, `dart:core` + camada reativa (puro).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_observer.dart';

/// Limpeza registrada via `onCleanup` (executa antes da próxima rodada).
typedef KortexCleanup = void Function();

/// Registra a limpeza da rodada atual do efeito.
typedef KortexEffectCleanupRegistrar = void Function(KortexCleanup cleanup);

/// Corpo do efeito; recebe o registrador de limpeza.
typedef KortexEffectCallback = void Function(
    KortexEffectCleanupRegistrar onCleanup);

/// Efeito colateral reativo com `onCleanup`, `debounce` e `dispose`.
///
/// Executa na criação; reagenda a cada mudança de dependência (imediato
/// ou após [debounce]). Auto-notificações disparadas pela própria execução
/// síncrona são ignoradas (guarda `_isRunning`).
class KortexEffect implements IKortexObserver, IKortexDisposable {
  /// Cria e executa o [effect] imediatamente.
  KortexEffect(this._effect, {this._debounce}) {
    _run();
  }

  final KortexEffectCallback _effect;
  final Duration? _debounce;
  final Set<IKortexReactiveNode> _deps = {};
  Timer? _timer;
  KortexCleanup? _cleanup;
  var _isCollecting = false;
  var _isRunning = false;
  var _isDisposed = false;

  @override
  void onRead(IKortexReactiveNode node) {
    if (_isDisposed) return;
    if (_isCollecting) {
      _deps.add(node);
      return;
    }
    if (_isRunning) return;
    _schedule();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cancelTimer();
    _runCleanup();
    _unsubscribeAll();
  }

  void _schedule() {
    final debounce = _debounce;
    if (debounce == null) {
      _rerun();
      return;
    }
    _cancelTimer();
    _timer = Timer(debounce, _rerun);
  }

  void _rerun() {
    if (_isDisposed) return;
    _runCleanup();
    _run();
  }

  void _run() {
    if (_isDisposed) return;
    _isRunning = true;
    _isCollecting = true;
    try {
      _unsubscribeAll();
      KortexTracker.runWithObserver(this, () => _effect(_registerCleanup));
    } finally {
      _isCollecting = false;
      _isRunning = false;
    }
  }

  void _registerCleanup(KortexCleanup cleanup) {
    _cleanup = cleanup;
  }

  void _runCleanup() {
    final cleanup = _cleanup;
    _cleanup = null;
    if (cleanup == null) return;
    cleanup();
  }

  void _cancelTimer() {
    final timer = _timer;
    _timer = null;
    if (timer == null) return;
    timer.cancel();
  }

  void _unsubscribeAll() {
    for (final dep in List.of(_deps)) {
      dep.removeObserver(this);
    }
    _deps.clear();
  }
}

/// Atalho ergonômico para `KortexEffect(...)`.
KortexEffect kortexEffect(
  KortexEffectCallback effect, {
  Duration? debounce,
}) =>
    KortexEffect(effect, debounce: debounce);

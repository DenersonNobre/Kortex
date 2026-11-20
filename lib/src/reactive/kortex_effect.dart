/// Automatic reaction to signals in pure Dart (`KortexEffect`).
///
/// SRP: re-run the effect when its dependencies change, with cleanup
/// (`onCleanup`), debouncing and explicit disposal. It does NOT hold an
/// observable value (it is not a node) nor batch notifications.
///
/// Patterns: Observer (leaf) + Debounce via a `dart:async` Timer.
/// Dependencies: `dart:async`, `dart:core` + the reactive layer (pure).
library;

import 'dart:async';

import 'kortex_disposable.dart';
import 'kortex_observer.dart';

/// Cleanup registered through `onCleanup` (runs before the next round).
typedef KortexCleanup = void Function();

/// Registers the cleanup of the effect's current round.
typedef KortexEffectCleanupRegistrar = void Function(KortexCleanup cleanup);

/// Effect body; receives the cleanup registrar.
typedef KortexEffectCallback = void Function(
  KortexEffectCleanupRegistrar onCleanup,
);

/// Reactive side effect with `onCleanup`, `debounce` and `dispose`.
///
/// Runs on creation and is rescheduled on every dependency change
/// (immediately or after [debounce]). Self-triggered notifications raised by
/// the synchronous execution are ignored (`_isRunning` guard).
class KortexEffect implements IKortexObserver, IKortexDisposable {
  /// Creates and immediately runs the [effect].
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

/// Ergonomic shortcut for `KortexEffect(...)`.
KortexEffect kortexEffect(KortexEffectCallback effect, {Duration? debounce}) =>
    KortexEffect(effect, debounce: debounce);

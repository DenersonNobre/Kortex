/// Observation graph and reactive transaction (`KortexTracker`, batch).
///
/// SRP: track which observer reads which node and consolidate notifications
/// into a batch with a deduplicated queue. It does NOT store values, derive
/// computeds or run effects (those are the nodes' and observers' jobs).
///
/// Patterns: Observer (explicit subscription) + Unit of Work (batch flushed
/// at the outermost exit, including under exceptions).
/// Dependencies: `dart:core` only (pure — no Flutter, no `BuildContext`).
library;

import 'kortex_disposable.dart';

/// Receives the notification that a node was read or changed.
///
/// Called at two moments: during dependency collection (inside
/// `KortexTracker.runWithObserver`) and when changes are dispatched. Each
/// observer distinguishes collection from invalidation by its own state.
abstract interface class IKortexObserver {
  /// Reacts to the read or change of [node].
  void onRead(IKortexReactiveNode node);
}

/// Observable source that manages subscribers and disposal.
abstract interface class IKortexReactiveNode implements IKortexDisposable {
  /// Subscribes [observer] (idempotent).
  void addObserver(IKortexObserver observer);

  /// Unsubscribes [observer] (no effect when absent).
  void removeObserver(IKortexObserver observer);

  /// Releases subscribers. A later read through the tracker does not resubscribe.
  @override
  void dispose();
}

/// Tracking frame: active observer plus an optional node collector.
class _TrackingFrame {
  _TrackingFrame(this.observer, this.onTrack);

  final IKortexObserver observer;
  final void Function(IKortexReactiveNode)? onTrack;
}

/// Deduplicated queue of pending notifications (one notice per observer).
class _PendingFlush {
  final Map<IKortexObserver, IKortexReactiveNode> _entries = {};

  /// Enqueues [observer] notified by [node] (the first node wins).
  void add(IKortexReactiveNode node, IKortexObserver observer) {
    _entries.putIfAbsent(observer, () => node);
  }

  /// Dispatches everything and empties the queue.
  void flush() {
    if (_entries.isEmpty) return;
    final snapshot = Map.of(_entries);
    _entries.clear();
    _notifyEach(snapshot);
  }

  void _notifyEach(Map<IKortexObserver, IKortexReactiveNode> snapshot) {
    for (final entry in snapshot.entries) {
      _notifyOne(entry.key, entry.value);
    }
  }

  void _notifyOne(IKortexObserver observer, IKortexReactiveNode node) {
    observer.onRead(node);
  }
}

/// Internal coordinator of reactive tracking (not exported by the barrel).
///
/// A stack of frames (`runWithObserver`/`recordRead`), a batch depth counter
/// (`batch`) and tracking suspension (`untracked`).
class KortexTracker {
  KortexTracker._();

  static final List<_TrackingFrame> _frames = [];
  static final _PendingFlush _pending = _PendingFlush();
  static var _batchDepth = 0;

  /// Runs [action] collecting reads into [observer].
  static T runWithObserver<T>(
    IKortexObserver observer,
    T Function() action, {
    void Function(IKortexReactiveNode)? onTrack,
  }) {
    _frames.add(_TrackingFrame(observer, onTrack));
    try {
      return action();
    } finally {
      _frames.removeLast();
    }
  }

  /// Records the read of [node] by the observer on top of the stack.
  ///
  /// With no active frame it does nothing (untracked read).
  static void recordRead(IKortexReactiveNode node) {
    if (_frames.isEmpty) return;
    _trackInTopFrame(node);
  }

  /// Schedules [observers] of [node]: immediately outside a batch, queued inside.
  static void notifyChange(
    IKortexReactiveNode node,
    Set<IKortexObserver> observers,
  ) {
    if (_batchDepth > 0) {
      _stageAll(node, observers);
      return;
    }
    _dispatchNow(node, observers);
  }

  /// Groups mutations: observers are notified once when the outermost batch ends.
  ///
  /// On exception the queue is flushed anyway (the state already changed).
  static void batch(void Function() action) {
    _batchDepth++;
    try {
      action();
    } finally {
      _batchDepth--;
      _flushIfOutermost();
    }
  }

  /// Runs [action] without recording reads (suspends the stack).
  static T untracked<T>(T Function() action) {
    if (_frames.isEmpty) return action();
    return _runDetached(action);
  }

  static void _trackInTopFrame(IKortexReactiveNode node) {
    final frame = _frames.last;
    final observer = frame.observer;
    node.addObserver(observer);
    observer.onRead(node);
    _notifyTrack(frame, node);
  }

  static void _notifyTrack(_TrackingFrame frame, IKortexReactiveNode node) {
    final onTrack = frame.onTrack;
    if (onTrack == null) return;
    onTrack(node);
  }

  static void _stageAll(
    IKortexReactiveNode node,
    Set<IKortexObserver> observers,
  ) {
    for (final observer in observers) {
      _pending.add(node, observer);
    }
  }

  static void _dispatchNow(
    IKortexReactiveNode node,
    Set<IKortexObserver> observers,
  ) {
    final snapshot = List.of(observers);
    for (final observer in snapshot) {
      observer.onRead(node);
    }
  }

  static void _flushIfOutermost() {
    if (_batchDepth > 0) return;
    _pending.flush();
  }

  static T _runDetached<T>(T Function() action) {
    final suspended = List.of(_frames);
    _frames.clear();
    try {
      return action();
    } finally {
      _frames.addAll(suspended);
    }
  }
}

/// Groups signal mutations without glitches (see [KortexTracker.batch]).
void kortexBatch(void Function() action) => KortexTracker.batch(action);

/// Reads signals without registering a dependency (see [KortexTracker.untracked]).
T kortexUntracked<T>(T Function() action) => KortexTracker.untracked(action);

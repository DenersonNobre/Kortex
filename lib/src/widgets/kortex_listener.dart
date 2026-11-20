/// Safe UI side effects (`KortexListener`).
///
/// SRP: separate the pure read (`watch`, discovered in `initState`) from the
/// imperative effect (`listener`, always outside the build phase). It does NOT
/// rebuild the UI (that is `KortexWatch`) nor hold values.
///
/// Patterns: Observer with initial collection + `Scheduler` phase guard.
/// Dependencies: Flutter (`widgets`, `scheduler`) + the reactive layer.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';

/// Listens for changes and runs the effect with a real `BuildContext`.
typedef KortexContextListener<T> = void Function(BuildContext context, T value);

/// Runs [listener] when `watch()` changes (never during `build`).
class KortexListener<T> extends StatefulWidget {
  /// Creates the listener with the pure read [watch] and the effect
  /// [listener].
  const KortexListener({
    super.key,
    required this.watch,
    required this.listener,
    this.equals,
    this.fireImmediately = false,
    required this.child,
  });

  /// Pure read evaluated in `initState` to discover dependencies.
  final T Function() watch;

  /// Effect executed outside `build` when `watch()` changes.
  final KortexContextListener<T> listener;

  /// Equality of the change (defaults to `==`).
  final KortexEquals<T>? equals;

  /// Fires [listener] right after mounting with the initial value.
  final bool fireImmediately;

  /// Subtree that never rebuilds because of this widget.
  final Widget child;

  @override
  State<KortexListener<T>> createState() => _KortexListenerState<T>();
}

class _KortexListenerState<T> extends State<KortexListener<T>>
    implements IKortexObserver {
  final Set<IKortexReactiveNode> _deps = {};
  late T _current;
  var _collecting = false;

  @override
  void initState() {
    super.initState();
    _collecting = true;
    try {
      _current = KortexTracker.runWithObserver(this, widget.watch);
    } finally {
      _collecting = false;
    }
    if (widget.fireImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fire(_current));
    }
  }

  @override
  void onRead(IKortexReactiveNode node) {
    if (_collecting) {
      _deps.add(node);
      return;
    }
    _evaluate();
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _evaluate() {
    _unsubscribeAll();
    _collecting = true;
    late T next;
    try {
      next = KortexTracker.runWithObserver(this, widget.watch);
    } finally {
      _collecting = false;
    }
    if (_equal(_current, next)) {
      return;
    }
    _current = next;
    _fire(next);
  }

  bool _equal(T previous, T next) {
    final equals = widget.equals;
    if (equals != null) {
      return equals(previous, next);
    }
    return previous == next;
  }

  void _fire(T value) {
    if (!mounted) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _fire(value));
      return;
    }
    widget.listener(context, value);
  }

  void _unsubscribeAll() {
    for (final dep in List.of(_deps)) {
      dep.removeObserver(this);
    }
    _deps.clear();
  }
}

/// Granular rebuild with a static `child` (`KortexWatch`).
///
/// SRP: rebuild only this fragment when the signals it reads change,
/// preserving the immutable [child]. It does NOT filter by equality (that
/// is `KortexSelector`) nor run side effects (that is `KortexListener`).
///
/// Patterns: Observer collecting in `build` + `setState` outside the build phase.
/// Dependencies: Flutter (`widgets`, `scheduler`) + the reactive layer.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';

/// Builds reactive UI with an optional `child` preserved across rebuilds.
typedef KortexWatchBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

/// Fragment that rebuilds when any signal read in [builder] changes.
class KortexWatch extends StatefulWidget {
  /// Creates the observable fragment with [builder] and an optional static
  /// [child].
  const KortexWatch({super.key, required this.builder, this.child});

  /// Tracked read; the `child` is passed back unchanged on every rebuild.
  final KortexWatchBuilder builder;

  /// Immutable subtree preserved between rebuilds.
  final Widget? child;

  @override
  State<KortexWatch> createState() => _KortexWatchState();
}

class _KortexWatchState extends State<KortexWatch> implements IKortexObserver {
  final Set<IKortexReactiveNode> _deps = {};
  var _collecting = false;

  @override
  void onRead(IKortexReactiveNode node) {
    if (_collecting) {
      _deps.add(node);
      return;
    }
    _schedule();
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _unsubscribeAll();
    _collecting = true;
    try {
      return KortexTracker.runWithObserver(
        this,
        () => widget.builder(context, widget.child),
      );
    } finally {
      _collecting = false;
    }
  }

  void _schedule() {
    if (!mounted) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _rebuild());
      return;
    }
    _rebuild();
  }

  void _rebuild() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _unsubscribeAll() {
    for (final dep in List.of(_deps)) {
      dep.removeObserver(this);
    }
    _deps.clear();
  }
}

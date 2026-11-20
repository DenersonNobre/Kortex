/// Rebuild filtered by equality (`KortexSelector`).
///
/// SRP: rebuild only when the value of [selector] changes according to
/// [equals], delegating observation to an internal `KortexComputed` +
/// `KortexWatch`. It does NOT run side effects nor untracked reads.
///
/// Patterns: Composite (observable derived value + observable fragment).
/// Dependencies: Flutter + the `reactive` layers (no global state).
library;

import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';
import 'kortex_watch.dart';

/// Builds UI from the selection, rebuilding only when it changes.
typedef KortexSelectorBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  Widget? child,
);

/// Fragment observing `selector()` and rebuilding only on a real change.
class KortexSelector<T> extends StatefulWidget {
  /// Creates the selector with [selector], [builder], [equals] and [child].
  const KortexSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.equals,
    this.child,
  });

  /// Extracts the observed value (read in a tracked way).
  final T Function() selector;

  /// Builds the UI with the selected value and the untouched [child].
  final KortexSelectorBuilder<T> builder;

  /// Equality of the selection (defaults to `==`).
  final KortexEquals<T>? equals;

  /// Immutable subtree passed back unchanged on every rebuild.
  final Widget? child;

  @override
  State<KortexSelector<T>> createState() => _KortexSelectorState<T>();
}

class _KortexSelectorState<T> extends State<KortexSelector<T>> {
  late KortexComputed<T> _computed;

  @override
  void initState() {
    super.initState();
    _computed = _createComputed();
  }

  @override
  void didUpdateWidget(KortexSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _computed.dispose();
    _computed = _createComputed();
  }

  @override
  void dispose() {
    _computed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KortexWatch(
    builder: (context, _) =>
        widget.builder(context, _computed.value, widget.child),
  );

  KortexComputed<T> _createComputed() =>
      KortexComputed<T>(widget.selector, equals: widget.equals);
}

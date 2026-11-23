import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

// ---------------------------------------------------------------------------
// 1. avoid_undisposed_kortex_signal
// ---------------------------------------------------------------------------

/// BAD: `_count` is never registered with `autoDispose(...)` or `disposeBag`.
/// Without the `// ignore:` below, `kortex_lint` reports:
///   Reactive primitive '_count' is not registered with autoDispose() or disposeBag.add().
class LeakyController extends IKortexController {
  // ignore: avoid_undisposed_kortex_signal
  final _count = 0.kortex;

  IKortex<int> get count => _count.readonly;
}

/// GOOD: `_count` is registered in the constructor via `autoDispose(_count)`.
class CounterController extends IKortexController {
  CounterController() {
    autoDispose(_count);
  }

  final _count = 0.kortex;
  IKortex<int> get count => _count.readonly;

  void increment() => _count.update((v) => v + 1);
}

// ---------------------------------------------------------------------------
// 2. avoid_kortex_signal_in_build
// ---------------------------------------------------------------------------

/// BAD: creating a signal inside `build()` recreates it on every rebuild.
/// Without the `// ignore:` below, `kortex_lint` reports:
///   Avoid creating '.kortex' inside build(); it will be recreated on every rebuild.
class LeakyWidget extends StatelessWidget {
  const LeakyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_kortex_signal_in_build
    final localSignal = 0.kortex;
    return Text('${localSignal.value}');
  }
}

/// GOOD: `IKortexPage` reads state from a scoped `CounterController`.
class CounterPage extends IKortexPage<CounterController> {
  const CounterPage({super.key});

  @override
  Widget buildPage(BuildContext context, CounterController controller) {
    return KortexWatch(
      builder: (context, child) => Text('Count: ${controller.count.value}'),
    );
  }
}

void main() {
  runApp(
    KortexScope(
      providers: [
        KortexProvider<CounterController>(create: (_) => CounterController()),
      ],
      child: const MaterialApp(home: CounterPage()),
    ),
  );
}

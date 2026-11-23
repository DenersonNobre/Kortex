import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// Example controller following `kortex_lint` rules.
class CounterController extends IKortexController {
  CounterController() {
    // Registered with `autoDispose`, so `avoid_undisposed_kortex_signal` passes.
    autoDispose(_count);
  }

  final _count = 0.kortex;
  IKortex<int> get count => _count.readonly;

  void increment() => _count.update((v) => v + 1);
}

/// Example page following `kortex_lint` rules.
class CounterPage extends IKortexPage<CounterController> {
  const CounterPage({super.key});

  @override
  Widget buildPage(BuildContext context, CounterController controller) {
    // Reads controller state without creating signals inside `buildPage`,
    // so `avoid_kortex_signal_in_build` passes.
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

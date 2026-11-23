/// Complete, single-file example for the `kortex` pub.dev Example tab.
///
/// Demonstrates:
/// - `IKortexController` with constructor initialization and `autoDispose`;
/// - Encapsulation via private `KortexSignal` + public `IKortexReadonlySignal`;
/// - Lazy derivation with `KortexComputed` and async lock via `KortexCommand`;
/// - `StatelessWidget`-first UI with `IKortexPage`, `KortexWatch`,
///   `KortexSelector`, `KortexListener` and `KortexScope`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// Holds counter state and the simulated async save action.
///
/// Dependencies and initial resources are set up in the constructor (no magic
/// `onInit`), and every reactive primitive registered with `autoDispose` is
/// disposed automatically when the owning `KortexScope` unmounts.
class CounterController extends IKortexController {
  CounterController() {
    autoDispose(_count);

    // Derived lazily and cached; only notifies listeners when parity changes.
    isEven = autoDispose(KortexComputed(() => _count.value.isEven));

    // Prevents concurrent double-taps while `isExecuting.value` is true.
    save = autoDispose(
      KortexCommand<void, int>((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return _count.value;
      }),
    );
  }

  // Keep the mutable signal private so widgets cannot mutate state directly.
  final _count = 0.kortex;

  /// Read-only reactive view exposed to the UI.
  IKortex<int> get count => _count.readonly;

  /// Cached derived state indicating whether [count] is even.
  late final KortexComputed<bool> isEven;

  /// Async save command exposing `isExecuting` and `state`.
  late final KortexCommand<void, int> save;

  /// Increments the counter by 1.
  void increment() => _count.update((value) => value + 1);

  /// Decrements the counter by 1.
  void decrement() => _count.update((value) => value - 1);
}

/// `StatelessWidget` page that resolves [CounterController] via `BuildContext`.
class CounterPage extends IKortexPage<CounterController> {
  /// Creates the counter page.
  const CounterPage({super.key});

  @override
  Widget buildPage(BuildContext context, CounterController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kortex — minimal example')),
      // `KortexListener` separates pure `watch` reads from imperative side
      // effects (`SnackBar`, navigation), running safely outside `build`.
      body: KortexListener<IKortexAsyncState<int>?>(
        watch: () => controller.save.state.value,
        listener: (listenerContext, state) {
          if (state case KortexAsyncData(value: final total)) {
            ScaffoldMessenger.of(listenerContext)
                .showSnackBar(SnackBar(content: Text('Saved: $total')));
          }
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only this subtree rebuilds when `controller.count.value` changes.
              KortexWatch(
                builder: (context, child) =>
                    Text('Clicks: ${controller.count.value}'),
              ),
              // Rebuilds only when the selected boolean changes.
              KortexSelector<bool>(
                selector: () => controller.isEven.value,
                builder: (context, even, child) => Text(even ? 'even' : 'odd'),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'decrement',
                    icon: const Icon(Icons.remove),
                    onPressed: controller.decrement,
                  ),
                  IconButton(
                    tooltip: 'increment',
                    icon: const Icon(Icons.add),
                    onPressed: controller.increment,
                  ),
                ],
              ),
              // Reacts to the command's `isExecuting` signal to swap UI states.
              KortexWatch(
                builder: (context, child) {
                  if (controller.save.isExecuting.value) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () => controller.save.execute(null),
                    child: const Text('Save'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Builds the app with `KortexScope` owning [CounterController]'s lifecycle.
Widget createApp() => KortexScope(
  providers: [
    KortexProvider<CounterController>(create: (_) => CounterController()),
  ],
  child: const MaterialApp(home: CounterPage()),
);

/// Entry point of the example app.
void main() => runApp(createApp());

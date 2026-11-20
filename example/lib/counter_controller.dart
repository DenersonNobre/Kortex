/// Counter controller of the minimal example.
///
/// SRP: expose the reactive counter and the save operation with a
/// double-trigger lock. It does NOT do UI, routing or real persistence.
///
/// Patterns: `IKortexController` with initialization in the constructor.
/// Dependencies: `kortex` (pure + scope) and `dart:async` via `Future`.
library;

import 'package:kortex/kortex.dart';

/// Counter with simulated async saving.
class CounterController extends IKortexController {
  /// Registers the signal and the command in the `disposeBag` (auto-disposed).
  CounterController() {
    autoDispose(count);
    save = autoDispose(
      KortexCommand<void, int>((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return count.value;
      }),
    );
  }

  /// The counter (reactive read, encapsulated write).
  final KortexSignal<int> count = KortexSignal(0);

  /// Save operation with `isExecuting` and a double-trigger lock.
  late final KortexCommand<void, int> save;

  /// Increments the counter.
  void increment() => count.update((value) => value + 1);

  /// Decrements the counter.
  void decrement() => count.update((value) => value - 1);
}

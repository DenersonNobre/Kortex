/// Complete, single-file example for the `kortex` pub.dev Example tab.
///
/// Demonstrates:
/// - `IKortexController` with constructor initialization and `autoDispose`;
/// - Ergonomic extensions (`.kortex`, `.kortexList`, `.kortexMap`, `.kortexSet`);
/// - Encapsulation via short readonly aliases (`IKortex`, `IKortexList`,
///   `IKortexMap`, `IKortexSet`);
/// - Lazy derivation with `KortexComputed` and async lock via `KortexCommand`;
/// - `StatelessWidget`-first UI with `IKortexPage`, `KortexWatch`,
///   `KortexSelector`, `KortexListener` and `KortexScope`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// Holds counter state, reactive collections, and the simulated save action.
///
/// Dependencies and initial resources are set up in the constructor (no magic
/// `onInit`), and every reactive primitive registered with `autoDispose` is
/// disposed automatically when the owning `KortexScope` unmounts.
class CounterController extends IKortexController {
  CounterController() {
    autoDispose(_count);
    autoDispose(_history);
    autoDispose(_bookmarks);
    autoDispose(_stats);

    // Derived lazily and cached; only notifies listeners when parity changes.
    isEven = autoDispose(KortexComputed(() => _count.value.isEven));

    // Prevents concurrent double-taps while `isExecuting.value` is true.
    save = autoDispose(
      KortexCommand<void, int>((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final snapshot = _count.value;
        kortexBatch(() {
          _history.add(snapshot);
          _stats['saves'] = (_stats['saves'] ?? 0) + 1;
        });
        return snapshot;
      }),
    );
  }

  // Keep mutable reactive primitives private so widgets cannot mutate them.
  final Kortex<int> _count = 0.kortex;
  final _history = <int>[].kortexList;
  final _bookmarks = <int>{}.kortexSet;
  final _stats = <String, int>{'saves': 0}.kortexMap;

  /// Read-only reactive views exposed to the UI via short aliases.
  IKortex<int> get count => _count.readonly;
  IKortexList<int> get history => _history.readonly;
  IKortexSet<int> get bookmarks => _bookmarks.readonly;
  IKortexMap<String, int> get stats => _stats.readonly;

  /// Cached derived state indicating whether [count] is even.
  late final KortexComputed<bool> isEven;

  /// Async save command exposing `isExecuting` and `state`.
  late final KortexCommand<void, int> save;

  /// Increments the counter by 1.
  void increment() => _count.update((value) => value + 1);

  /// Decrements the counter by 1.
  void decrement() => _count.update((value) => value - 1);

  /// Toggles the current counter value in [bookmarks].
  void toggleBookmark() {
    final current = _count.value;
    if (!_bookmarks.add(current)) {
      _bookmarks.remove(current);
    }
  }
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
                  IconButton(
                    tooltip: 'bookmark',
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: controller.toggleBookmark,
                  ),
                ],
              ),
              // Reacts to the reactive collections (`history`, `stats`, `bookmarks`).
              KortexWatch(
                builder: (context, child) => Text(
                  'Saves (${controller.stats['saves'] ?? 0}): '
                  '${controller.history.value.join(', ')} • '
                  'Bookmarks: ${controller.bookmarks.length}',
                ),
              ),
              const SizedBox(height: 8),
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

/// Builds the app with `KortexMaterialApp` owning [CounterController]'s lifecycle.
Widget createApp() => KortexMaterialApp(
  providers: [
    KortexProvider<CounterController>(create: (_) => CounterController()),
  ],
  app: const MaterialApp(home: CounterPage()),
);

/// Entry point of the example app.
void main() => runApp(createApp());

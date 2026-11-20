/// Counter page of the minimal example (`StatelessWidget`).
///
/// SRP: compose `KortexWatch`/`KortexSelector`/`KortexListener` over the
/// `CounterController` resolved in the scope. It does NOT manage state.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'counter_controller.dart';

/// Single screen of the example: counter, even/odd and save with a notice.
class CounterPage extends IKortexPage<CounterController> {
  /// Creates the counter page.
  const CounterPage({super.key});

  @override
  Widget buildPage(BuildContext context, CounterController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kortex — minimal example')),
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
              KortexWatch(
                builder: (context, child) =>
                    Text('Clicks: ${controller.count.value}'),
              ),
              KortexSelector<bool>(
                selector: () => controller.count.value.isEven,
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

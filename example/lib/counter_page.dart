/// Página do contador do exemplo mínimo (`StatelessWidget`).
///
/// SRP: compor `KortexWatch`/`KortexSelector`/`KortexListener` sobre o
/// `CounterController` resolvido no escopo. NÃO faz: gerenciar estado.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'counter_controller.dart';

/// Tela única do exemplo: contador, par/ímpar e salvamento com aviso.
class CounterPage extends IKortexPage<CounterController> {
  /// Cria a página do contador.
  const CounterPage({super.key});

  @override
  Widget buildPage(BuildContext context, CounterController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kortex — exemplo mínimo')),
      body: KortexListener<IKortexAsyncState<int>?>(
        watch: () => controller.save.state.value,
        listener: (listenerContext, state) {
          if (state case KortexAsyncData(value: final total)) {
            ScaffoldMessenger.of(listenerContext)
                .showSnackBar(SnackBar(content: Text('Salvo: $total')));
          }
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KortexWatch(
                builder: (context, child) =>
                    Text('Cliques: ${controller.count.value}'),
              ),
              KortexSelector<bool>(
                selector: () => controller.count.value.isEven,
                builder: (context, even, child) => Text(even ? 'par' : 'ímpar'),
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
                    child: const Text('Salvar'),
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

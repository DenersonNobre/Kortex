/// App de exemplo do pacote `kortex` (só API pública, zero deps externas).
///
/// Demonstra: `KortexScope` com resolução entre irmãos
/// (`datasource → repository → controller`), `IKortexPage` sem estado,
/// `KortexWatch`/`KortexSelector`/`KortexListener`, `KortexResource` com
/// `previousValue` e `KortexCommand` com trava de duplo clique.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// Fonte simulada com latência (posse do `KortexScope`).
class CounterDatasource implements IKortexDisposable {
  /// Simula leitura remota do total.
  Future<int> loadTotal() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 42;
  }

  /// Simula persistência remota do [value].
  Future<void> save(int value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  void dispose() {}
}

/// Repositório fino sobre o datasource (resolvido entre irmãos).
class CounterRepository {
  /// Cria o repositório sobre [datasource].
  CounterRepository(this._datasource);

  final CounterDatasource _datasource;

  /// Carrega o total remoto.
  Future<int> loadTotal() => _datasource.loadTotal();

  /// Persiste o [value] remoto.
  Future<void> save(int value) => _datasource.save(value);
}

/// Controller do contador (inicialização só no construtor).
class CounterController extends IKortexController {
  /// Conecta o [repository] e registra as primitivas no `disposeBag`.
  CounterController(this._repository) {
    autoDispose(_count);
    message = autoDispose(kortexResource(_repository.loadTotal));
    save = autoDispose(
      kortexCommand<void, int>((_) async {
        await _repository.save(_count.value);
        return _count.value;
      }),
    );
  }

  final CounterRepository _repository;
  final KortexSignal<int> _count = KortexSignal(0);

  /// Total remoto com `previousValue` durante `refresh()`.
  late final KortexResource<int> message;

  /// Salvamento com trava de reentrância.
  late final KortexCommand<void, int> save;

  /// Contador local (leitura reativa, escrita encapsulada).
  IKortexReadonlySignal<int> get count => _count.readonly;

  /// Incrementa o contador.
  void increment() => _count.update((current) => current + 1);

  /// Decrementa o contador.
  void decrement() => _count.update((current) => current - 1);
}

/// Página do contador (`StatelessWidget`, controller via escopo).
class CounterPage extends IKortexPage<CounterController> {
  /// Cria a página do contador.
  const CounterPage({super.key});

  @override
  Widget buildPage(BuildContext context, CounterController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kortex Exemplo')),
      body: KortexListener<IKortexAsyncState<int>?>(
        watch: () => controller.save.state.value,
        listener: (listenerContext, state) {
          if (state case KortexAsyncData(value: final total)) {
            ScaffoldMessenger.of(listenerContext)
                .showSnackBar(SnackBar(content: Text('Salvo: $total')));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            KortexResourceBuilder<int>(
              resource: controller.message,
              loading: (context) => const CircularProgressIndicator(),
              error: (context, error, stackTrace) => TextButton(
                onPressed: () => controller.message.refresh(),
                child: const Text('retry'),
              ),
              data: (context, value) => Text('Total: $value'),
            ),
            TextButton(
              onPressed: () => controller.message.refresh(),
              child: const Text('Recarregar'),
            ),
            const SizedBox(height: 16),
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
    );
  }
}

/// Monta o app com o escopo raiz (`datasource → repository → controller`).
Widget createApp() => KortexScope(
  providers: [
    KortexProvider<CounterDatasource>(create: (_) => CounterDatasource()),
    KortexProvider<CounterRepository>(
      create: (scope) => CounterRepository(scope.read<CounterDatasource>()),
    ),
    KortexProvider<CounterController>(
      create: (scope) => CounterController(scope.read<CounterRepository>()),
    ),
  ],
  child: const MaterialApp(home: CounterPage()),
);

/// Entrada do app de exemplo.
void main() => runApp(createApp());

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';

/// Controller concreto para o teste do barrel.
class _BarrelController extends IKortexController {}

/// Página concreta para o teste do barrel.
class _BarrelPage extends IKortexPage<_BarrelController> {
  const _BarrelPage();

  @override
  Widget buildPage(BuildContext context, _BarrelController controller) =>
      const Text('barrel', textDirection: TextDirection.ltr);
}

void main() {
  test('barrel expõe a API reativa pura', () {
    final bag = KortexDisposeBag();
    final signal = kortexSignal(1);
    final list = kortexList<int>([1]);
    final map = kortexMap<String, int>({'a': 1});
    final computed = kortexComputed(() => signal.value * 2);
    final effect = kortexEffect((_) {});
    final resource = kortexResource<int>(() async => 1, immediate: false);
    final streamResource = kortexStreamResource<int>(
      () => const Stream<int>.empty(),
      immediate: false,
    );
    final command = kortexCommand<String, int>((_) async => 1);

    expect(bag.isDisposed, isFalse);
    expect(signal.value, 1);
    expect(list.readonly.value, [1]);
    expect(map.readonly.value, {'a': 1});
    expect(computed.value, 2);
    expect(resource.state.value.isLoading, isTrue);
    expect(streamResource.state.value.isLoading, isTrue);
    expect(command.isExecuting.value, isFalse);

    IKortexReadonlySignal<int> readonly = signal;
    IKortexAsyncState<int> asyncState = const KortexAsyncData(1);
    expect(readonly.value, 1);
    expect(asyncState.valueOrNull, 1);

    effect.dispose();
    resource.dispose();
    streamResource.dispose();
    command.dispose();
    computed.dispose();
    list.dispose();
    map.dispose();
    signal.dispose();
    bag.dispose();
  });

  testWidgets('barrel expõe escopo, página e widgets', (tester) async {
    final watch = KortexWatch(builder: (context, child) => const SizedBox());
    final selector = KortexSelector<int>(
      selector: () => 1,
      builder: (context, value, child) => const SizedBox(),
    );
    final listener = KortexListener<int>(
      watch: () => 1,
      listener: (context, value) {},
      child: const SizedBox(),
    );
    expect(watch, isA<KortexWatch>());
    expect(selector, isA<KortexSelector<int>>());
    expect(listener, isA<KortexListener<int>>());

    String? seen;
    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<_BarrelController>(
              create: (_) => _BarrelController(),
            ),
          ],
          child: Builder(
            builder: (context) {
              seen = context
                  .watchKortex<_BarrelController>()
                  .runtimeType
                  .toString();
              return const _BarrelPage();
            },
          ),
        ),
      ),
    );

    expect(find.text('barrel'), findsOneWidget);
    expect(seen, contains('_BarrelController'));
  });
}

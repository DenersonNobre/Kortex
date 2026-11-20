import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';

/// Observador de teste que conta notificações (zera após assinar).
class _Probe implements IKortexObserver {
  var reads = 0;

  @override
  void onRead(IKortexReactiveNode node) => reads++;
}

void main() {
  group('IKortexAsyncState', () {
    test('expõe isLoading, isRefreshing e valueOrNull', () {
      const loading = KortexAsyncLoading<String>();
      const refreshing = KortexAsyncLoading<String>(previousValue: 'v1');
      const data = KortexAsyncData<String>('v2');
      final error = KortexAsyncError<String>(StateError('boom'));

      expect(loading.isLoading, isTrue);
      expect(loading.isRefreshing, isFalse);
      expect(loading.valueOrNull, isNull);

      expect(refreshing.isLoading, isTrue);
      expect(refreshing.isRefreshing, isTrue);
      expect(refreshing.valueOrNull, 'v1');

      expect(data.isLoading, isFalse);
      expect(data.isRefreshing, isFalse);
      expect(data.valueOrNull, 'v2');

      expect(error.isLoading, isFalse);
      expect(error.valueOrNull, isNull);
      expect(error.error, isStateError);
    });
  });

  group('KortexResource', () {
    test('immediate:true inicia em Loading sem chamar além da conta', () async {
      final gate = Completer<String>();
      var calls = 0;
      final resource = KortexResource<String>(() {
        calls++;
        return gate.future;
      });

      expect(resource.state.value.isLoading, isTrue);
      expect(calls, 1);

      gate.complete('ok');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(resource.state.value, isA<KortexAsyncData<String>>());
      resource.dispose();
    });

    test('immediate:false não carrega até refresh()', () {
      var calls = 0;
      final resource = KortexResource<String>(() {
        calls++;
        return Future.value('v1');
      }, immediate: false);

      expect(calls, 0);
      expect(resource.state.value.isLoading, isTrue);
      resource.dispose();
    });

    test('refresh em voo preserva previousValue (isRefreshing)', () async {
      final second = Completer<String>();
      var calls = 0;
      final resource = KortexResource<String>(
        () => ++calls == 1 ? Future.value('v1') : second.future,
        immediate: false,
      );

      await resource.refresh();
      final inFlight = resource.refresh();

      final loading = resource.state.value;
      expect(loading, isA<KortexAsyncLoading<String>>());
      expect(loading.isRefreshing, isTrue);
      expect(loading.valueOrNull, 'v1');

      second.complete('v2');
      await inFlight;
      expect(resource.state.value.valueOrNull, 'v2');
      resource.dispose();
    });

    test('resposta tardia da 1a carga é descartada', () async {
      final first = Completer<String>();
      final second = Completer<String>();
      var calls = 0;
      final resource = KortexResource<String>(
        () => ++calls == 1 ? first.future : second.future,
        immediate: false,
      );

      final slow = resource.refresh();
      final fast = resource.refresh();

      second.complete('segundo');
      await fast;
      first.complete('primeiro');
      await slow;

      final state = resource.state.value;
      expect(state, isA<KortexAsyncData<String>>());
      expect(state.valueOrNull, 'segundo');
      resource.dispose();
    });

    test('dispose em voo ignora tardia e refresh lança StateError', () async {
      final gate = Completer<String>();
      final resource = KortexResource<String>(() => gate.future);

      final inFlight = resource.refresh();
      resource.dispose();

      expect(resource.isDisposed, isTrue);
      gate.complete('tarde');
      await inFlight;

      expect(() => resource.refresh(), throwsStateError);
      expect(() => resource.state.value, throwsStateError);
    });

    test('falha do loader publica KortexAsyncError', () async {
      final resource = KortexResource<String>(
        () => Future<String>.error(StateError('boom')),
        immediate: false,
      );

      await resource.refresh();

      final state = resource.state.value;
      expect(state, isA<KortexAsyncError<String>>());
      expect((state as KortexAsyncError<String>).error, isStateError);
      resource.dispose();
    });

    test('transições notificam observadores do state', () async {
      final resource = KortexResource<String>(
        () => Future.value('v1'),
        immediate: false,
      );
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => resource.state.value);
      probe.reads = 0;

      await resource.refresh();

      expect(probe.reads, 2);
      resource.dispose();
    });
  });
}

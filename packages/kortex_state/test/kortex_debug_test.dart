import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';

final class _RecordingDebugObserver implements IKortexDebugObserver {
  final List<IKortexDebugEvent> events = [];

  @override
  void onEvent(IKortexDebugEvent event) {
    events.add(event);
  }
}

void main() {
  group('KortexDebug', () {
    tearDown(() => KortexDebug.observer = null);

    test(
      'emite eventos reais de criacao, atualizacao e descarte de KortexSignal',
      () {
        final observer = _RecordingDebugObserver();
        KortexDebug.observer = observer;

        final count = KortexSignal<int>(0);
        count.value = 1;
        count.value = 1; // sem mudanca -> nao emite update
        count.dispose();

        expect(observer.events, hasLength(3));
        expect(observer.events[0], isA<KortexDebugCreated>());
        expect(
          observer.events[1],
          isA<KortexDebugUpdated>().having((e) => e.value, 'value', 1),
        );
        expect(observer.events[2], isA<KortexDebugDisposed>());
      },
    );

    test('nao falha quando observer e null', () {
      KortexDebug.observer = null;
      final signal = KortexSignal<int>(0);
      signal.value = 42;
      expect(signal.value, 42);
      signal.dispose();
    });
  });
}

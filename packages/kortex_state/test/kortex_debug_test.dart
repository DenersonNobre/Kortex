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

    test('emite eventos para o observer em modo debug', () {
      final observer = _RecordingDebugObserver();
      KortexDebug.observer = observer;

      KortexDebug.emit(
        const KortexDebugCreated(type: 'KortexSignal', label: 'count'),
      );
      KortexDebug.emit(
        const KortexDebugUpdated(
          type: 'KortexSignal',
          label: 'count',
          value: 1,
        ),
      );
      KortexDebug.emit(
        const KortexDebugDisposed(type: 'KortexSignal', label: 'count'),
      );

      expect(observer.events, hasLength(3));
      expect(observer.events[0], isA<KortexDebugCreated>());
      expect(observer.events[1], isA<KortexDebugUpdated>());
      expect(observer.events[2], isA<KortexDebugDisposed>());
    });

    test('nao falha quando observer e null', () {
      KortexDebug.observer = null;
      expect(
        () => KortexDebug.emit(const KortexDebugCreated(type: 'KortexSignal')),
        returnsNormally,
      );
    });
  });
}

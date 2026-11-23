import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_persist/kortex_persist.dart';

void main() {
  group('KortexPersistedSignal', () {
    test('hydrates existing value from storage', () async {
      final storage = KortexMemoryStorage()..write('theme_dark', 'true');

      final signal = kortexPersistedSignal<bool>(
        key: 'theme_dark',
        initialValue: false,
        storage: storage,
        encode: (v) => v.toString(),
        decode: (raw) => raw == 'true',
      );

      await signal.hydrated;
      expect(signal.value, isTrue);
      signal.dispose();
    });

    test('persists changes and clears storage', () async {
      final storage = KortexMemoryStorage();
      final signal = kortexPersistedSignal<int>(
        key: 'counter',
        initialValue: 0,
        storage: storage,
        encode: (v) => v.toString(),
        decode: int.parse,
      );

      await signal.hydrated;
      signal.value = 42;
      await Future<void>.delayed(Duration.zero);
      expect(storage.read('counter'), '42');

      await signal.clear();
      expect(storage.read('counter'), isNull);
      expect(signal.value, 0);
      signal.dispose();
    });
  });
}

import 'dart:async';

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

    test(
      'mutacao durante hydrate nao e sobrescrita por leitura tardia',
      () async {
        final storage = _ControlledStorage()
          ..readCompleter = Completer<String?>();
        final signal = kortexPersistedSignal<String>(
          key: 'name',
          initialValue: 'init',
          storage: storage,
          encode: (v) => v,
          decode: (raw) => raw,
        );

        // Mutacao ocorre antes do read() terminar.
        signal.value = 'fresh';
        storage.readCompleter!.complete('stale');

        await signal.hydrated;
        await signal.flush();

        expect(signal.value, 'fresh');
        expect(storage.data['name'], 'fresh');
        signal.dispose();
      },
    );

    test('clear durante write pendente garante estado final limpo', () async {
      final storage = _ControlledStorage()..writeCompleter = Completer<void>();
      final signal = kortexPersistedSignal<String>(
        key: 'token',
        initialValue: 'none',
        storage: storage,
        encode: (v) => v,
        decode: (raw) => raw,
      );
      await signal.hydrated;

      signal.value = 'abc';
      final clearFuture = signal.clear();
      storage.writeCompleter!.complete();
      await clearFuture;

      expect(signal.value, 'none');
      expect(storage.data['token'], isNull);
      signal.dispose();
    });

    test('falha no write e exposta via onError sem crash silencioso', () async {
      final errors = <Object>[];
      final storage = _ControlledStorage()..failWrite = true;
      final signal = kortexPersistedSignal<int>(
        key: 'count',
        initialValue: 0,
        storage: storage,
        encode: (v) => v.toString(),
        decode: int.parse,
        onError: (error, _) => errors.add(error),
      );
      await signal.hydrated;

      signal.value = 10;
      await signal.flush();

      expect(errors, hasLength(1));
      expect(errors.single, isStateError);
      expect(signal.lastError, isStateError);
      signal.dispose();
    });

    test(
      'falha no write sem onError expoe lastError sem excecao nao tratada',
      () async {
        final storage = _ControlledStorage()..failWrite = true;
        final signal = kortexPersistedSignal<int>(
          key: 'count',
          initialValue: 0,
          storage: storage,
          encode: (v) => v.toString(),
          decode: int.parse,
        );
        await signal.hydrated;

        signal.value = 10;
        await signal.flush();

        expect(signal.lastError, isStateError);
        signal.dispose();
      },
    );

    test('falha no write sem onError expoe lastError sem excecao nao tratada', () async {
      final storage = _ControlledStorage()..failWrite = true;
      final signal = kortexPersistedSignal<int>(
        key: 'count',
        initialValue: 0,
        storage: storage,
        encode: (v) => v.toString(),
        decode: int.parse,
      );
      await signal.hydrated;

      signal.value = 10;
      await signal.flush();

      expect(signal.lastError, isStateError);
      signal.dispose();
    });
  });
}

final class _ControlledStorage implements IKortexStorage {
  final Map<String, String> data = {};
  Completer<String?>? readCompleter;
  Completer<void>? writeCompleter;
  var failWrite = false;

  @override
  Future<String?> read(String key) async {
    if (readCompleter != null) {
      return readCompleter!.future;
    }
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeCompleter != null) {
      await writeCompleter!.future;
    }
    if (failWrite) {
      throw StateError('disk full');
    }
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

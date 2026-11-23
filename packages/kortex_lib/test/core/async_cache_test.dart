import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncCache (TTL)', () {
    test('dentro do TTL usa cache sem recarregar', () async {
      var agora = DateTime(2026, 1, 1);
      var chamadas = 0;
      final cache = AsyncCache<String>(
        duration: const Duration(minutes: 5),
        load: () async {
          chamadas++;
          return 'valor-$chamadas';
        },
        clock: () => agora,
      );

      expect(await cache.getOrLoad(), 'valor-1');
      agora = agora.add(const Duration(minutes: 1));
      expect(await cache.getOrLoad(), 'valor-1');
      expect(chamadas, 1);
    });

    test('expirado no TTL recarrega', () async {
      var agora = DateTime(2026, 1, 1);
      var chamadas = 0;
      final cache = AsyncCache<String>(
        duration: const Duration(minutes: 5),
        load: () async {
          chamadas++;
          return 'valor-$chamadas';
        },
        clock: () => agora,
      );

      await cache.getOrLoad();
      agora = agora.add(const Duration(minutes: 5));
      expect(await cache.getOrLoad(), 'valor-2');
      expect(chamadas, 2);
    });

    test('invalidate() força recarga imediata', () async {
      var chamadas = 0;
      final cache = AsyncCache<String>(
        duration: const Duration(minutes: 5),
        load: () async {
          chamadas++;
          return 'valor-$chamadas';
        },
      );

      await cache.getOrLoad();
      cache.invalidate();
      expect(await cache.getOrLoad(), 'valor-2');
      expect(chamadas, 2);
    });
  });
}

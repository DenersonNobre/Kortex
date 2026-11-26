import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('LazyProxy (GoF Proxy/Lazy)', () {
    test('não cria a instância até o primeiro acesso', () {
      var criadas = 0;
      final proxy = LazyProxy<String>(() {
        criadas++;
        return 'valor';
      });

      expect(criadas, 0);
      expect(proxy.instancia, 'valor');
      expect(criadas, 1);
    });

    test('cria uma única vez e devolve a mesma instância', () {
      var criadas = 0;
      final proxy = LazyProxy<String>(() {
        criadas++;
        return 'valor';
      });

      proxy.instancia;
      proxy.instancia;
      expect(criadas, 1);
    });

    test('mantém a referência estável da instância criada', () {
      final objeto = Object();
      final proxy = LazyProxy<Object>(() => objeto);

      expect(identical(proxy.instancia, objeto), isTrue);
      expect(identical(proxy.instancia, objeto), isTrue);
    });
  });
}

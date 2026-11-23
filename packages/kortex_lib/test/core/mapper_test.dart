import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

class TamanhoMapper implements IMapper<String, int> {
  @override
  int map(String source) => source.length;
}

void main() {
  group('IMapper', () {
    test('map unário transforma a fonte', () {
      expect(TamanhoMapper().map('abc'), 3);
    });

    test('extensão toMapped aplica o mapper', () {
      expect('quatro'.toMapped(TamanhoMapper()), 6);
    });

    test('toMappedList preserva ordem e tamanho', () {
      final saida = ['a', 'br', 'xyz'].toMappedList(TamanhoMapper());
      expect(saida, [1, 2, 3]);
    });

    test('toMappedList em lista vazia retorna []', () {
      expect(<String>[].toMappedList(TamanhoMapper()), isEmpty);
    });

    test('toMappedList aceita qualquer Iterable (Set)', () {
      final saida = {'a', 'abc'}.toMappedList(TamanhoMapper());
      expect(saida.toSet(), {1, 3});
    });
  });
}

import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

class _Par {
  final int id;
  final double price;
  const _Par(this.id, this.price);

  @override
  bool operator ==(Object other) =>
      other is _Par && other.id == id && other.price == price;

  @override
  int get hashCode => Object.hash(id, price);
}

ISpecification<_Par> _luxo() =>
    ISpecification<_Par>.of((par) => par.price >= 400);
ISpecification<_Par> _idPar() =>
    ISpecification<_Par>.of((par) => par.id.isEven);
ISpecification<_Par> _barato() =>
    ISpecification<_Par>.of((par) => par.price < 30);

void main() {
  const luxo = _Par(1, 500);
  const comum = _Par(2, 80);

  group('ISpecification.of + isSatisfiedBy', () {
    test('predicado simples decide o candidato', () {
      expect(_luxo().isSatisfiedBy(luxo), isTrue);
      expect(_luxo().isSatisfiedBy(comum), isFalse);
    });
  });

  group('composição and/or/not', () {
    test('and exige as duas especificações', () {
      final caroEPar = _luxo().and(_idPar());
      expect(caroEPar.isSatisfiedBy(luxo), isFalse, reason: '1 é ímpar');
      expect(caroEPar.isSatisfiedBy(const _Par(4, 420)), isTrue);
    });

    test('or aceita qualquer uma', () {
      final caroOuPar = _luxo().or(_idPar());
      expect(caroOuPar.isSatisfiedBy(luxo), isTrue);
      expect(
        caroOuPar.isSatisfiedBy(const _Par(4, 1)),
        isTrue,
        reason: 'par atende or',
      );
      expect(caroOuPar.isSatisfiedBy(const _Par(3, 1)), isFalse);
    });

    test('not inverte', () {
      final naoLuxo = _luxo().not();
      expect(naoLuxo.isSatisfiedBy(comum), isTrue);
      expect(naoLuxo.isSatisfiedBy(luxo), isFalse);
    });

    test('operadores & | compõem como and/or', () {
      final caroEPar = _luxo() & _idPar();
      final caroOuPar = _luxo() | _idPar();
      expect(caroOuPar.isSatisfiedBy(const _Par(4, 1)), isTrue);
      expect(caroEPar.isSatisfiedBy(const _Par(4, 500)), isTrue);
      expect(caroEPar.isSatisfiedBy(const _Par(3, 500)), isFalse);
    });

    test('composição aninhada funciona', () {
      final spec = _luxo().or(_barato()).and(_idPar().not());
      expect(spec.isSatisfiedBy(luxo), isTrue, reason: 'caro e ímpar');
      expect(
        spec.isSatisfiedBy(const _Par(4, 10)),
        isFalse,
        reason: 'par barato não',
      );
      expect(
        spec.isSatisfiedBy(const _Par(5, 10)),
        isTrue,
        reason: 'ímpar barato sim',
      );
    });
  });

  group('specs universais', () {
    test('ISpecification.all sempre satisfaz', () {
      expect(ISpecification<_Par>.all().isSatisfiedBy(luxo), isTrue);
    });

    test('ISpecification.none nunca satisfaz', () {
      expect(ISpecification<_Par>.none().isSatisfiedBy(luxo), isFalse);
    });
  });
}

import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

class _Record {
  const _Record({this.name, this.age});

  final String? name;
  final int? age;
}

class _RecordValidator extends ICustomValidator<_Record> {
  _RecordValidator() {
    ruleFor((record) => record.name, key: 'name').addValidation(NotEmpty());
    ruleFor(
      (record) => record.age,
      key: 'age',
    ).addValidation(GreaterThanZero());
  }
}

void main() {
  group('generic validators', () {
    test('NotEmpty validates nullable strings', () {
      expect(NotEmpty().validate(''), 'Não pode estar vazio');
      expect(NotEmpty().validate(null), 'Não pode estar vazio');
      expect(NotEmpty().validate('x'), isNull);
    });

    test('MinLength and MaxLength validate boundaries', () {
      expect(
        MinLength(length: 5).validate('abc'),
        'Deve ter no mínimo 5 caracteres',
      );
      expect(MinLength(length: 5).validate('abcde'), isNull);
      expect(
        MaxLength(length: 5).validate('abcdef'),
        'Deve ter no máximo 5 caracteres',
      );
      expect(MaxLength(length: 5).validate('abcde'), isNull);
    });

    test('Regex validates nullable input without throwing', () {
      final validator = Regex(regExp: RegExp(r'^\d+$'));

      expect(validator.validate('123'), isNull);
      expect(validator.validate('abc'), isNotNull);
      expect(validator.validate(null), isNotNull);
    });

    test('numeric validators check comparisons and ranges', () {
      expect(GreaterThanZero<int>().validate(1), isNull);
      expect(GreaterThanZero<int>().validate(0), 'Deve ser maior que zero');
      expect(GreaterThan<int>(value: 5).validate(6), isNull);
      expect(GreaterThan<int>(value: 5).validate(5), 'Deve ser maior que 5');
      expect(GreaterThan<int>(value: 5).validate(null), 'Deve ser maior que 5');
      expect(LessThan(value: 5).validate(4), isNull);
      expect(LessThan(value: 5).validate(5), 'Deve ser menor que 5');
      expect(LessThan(value: 5).validate(null), isNull);
      expect(Range(min: 1, max: 10).validate(5), isNull);
      expect(Range(min: 1, max: 10).validate(0), 'Deve estar entre 1 e 10');
      expect(Range(min: 1, max: 10).validate(null), 'Deve estar entre 1 e 10');
      expect(NotZero<int>().validate(1), isNull);
      expect(NotZero<int>().validate(0), 'Não pode ser zero');
    });

    test('string comparison validators', () {
      expect(EqualTo(value: 'abc').validate('abc'), isNull);
      expect(EqualTo(value: 'abc').validate('xyz'), 'Deve ser igual a abc');
      expect(DifferentFrom(value: 'abc').validate('xyz'), isNull);
      expect(
        DifferentFrom(value: 'abc').validate('abc'),
        'Deve ser diferente de abc',
      );
    });
  });

  group('ICustomValidator', () {
    test('acumula erros e limpa resultados entre execuções', () {
      final validator = _RecordValidator();

      expect(validator.validate(const _Record()), [
        'Não pode estar vazio',
        'Deve ser maior que zero',
      ]);
      expect(validator.validate(const _Record(name: 'Ada', age: 1)), isEmpty);
    });

    test('valida um campo e expõe callback por campo', () {
      final validator = _RecordValidator();

      expect(
        validator.validateField(const _Record(), 'name'),
        'Não pode estar vazio',
      );
      expect(
        validator.validateField(const _Record(name: 'Ada', age: 1), 'name'),
        isNull,
      );
      expect(
        validator.byField(const _Record(), 'name')('ignored'),
        'Não pode estar vazio',
      );
    });
  });
}

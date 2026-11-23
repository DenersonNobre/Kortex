import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('ValidEmail', () {
    test('accepts well-formed address and skips empty (optional)', () {
      expect(isValidEmail('user@example.com'), isTrue);
      expect(isValidEmail('first.last@sub.example.com.br'), isTrue);
      expect(isValidEmail('not-email'), isFalse);
      expect(isValidEmail('user@com'), isFalse);
      expect(isValidEmail(null), isFalse);
      expect(isValidEmail(''), isFalse);
    });

    test('accepts plus-addressing and long TLDs (RFC 5322 practical)', () {
      expect(isValidEmail('user+tag@example.com'), isTrue);
      expect(isValidEmail('user+tag+more@example.com'), isTrue);
      expect(isValidEmail('user@company.museum'), isTrue);
      expect(isValidEmail('user@domain.info'), isTrue);
      expect(isValidEmail("o'brien@example.com"), isTrue);
    });

    test('wrapper composes with NotEmpty: empty passes here', () {
      expect(ValidEmail().validate('user@example.com'), isNull);
      expect(ValidEmail().validate('not-email'), isNotNull);
      expect(ValidEmail().validate(''), isNull);
      expect(ValidEmail().validate(null), isNull);
      expect(ValidEmail(message: 'custom').validate('not-email'), 'custom');
    });
  });

  group('PasswordPolicy and ValidPassword', () {
    test('default policy requires length, letter, digit and symbol', () {
      const policy = PasswordPolicy();

      expect(policy.isSatisfiedBy('Abcdef1!'), isTrue);
      expect(policy.isSatisfiedBy('short1!'), isFalse);
      expect(policy.isSatisfiedBy('NoDigits!!'), isFalse);
      expect(policy.isSatisfiedBy('NoSymbols123'), isFalse);
      expect(policy.isSatisfiedBy('12345678!'), isFalse);
      expect(policy.isSatisfiedBy(null), isFalse);
    });

    test(
      'symbol accepts any non-alphanumeric char (aligned with strength)',
      () {
        const policy = PasswordPolicy();
        // Símbolos fora da lista ASCII antiga que passwordStrength já aceitava.
        expect(policy.isSatisfiedBy('Abcdef1~'), isTrue);
        expect(policy.isSatisfiedBy('Abcdef1+'), isTrue);
        expect(policy.isSatisfiedBy('Abcdef1['), isTrue);
        expect(policy.isSatisfiedBy('Abcdef1/'), isTrue);
        expect(policy.isSatisfiedBy("Abcdef1'"), isTrue);
        expect(policy.isSatisfiedBy('Abcdef1_-'), isTrue);
      },
    );

    test('policy is configurable', () {
      const relaxed = PasswordPolicy(
        minLength: 4,
        requireSymbol: false,
        requireDigit: false,
      );

      expect(relaxed.isSatisfiedBy('abcd'), isTrue);
      expect(relaxed.isSatisfiedBy('abc'), isFalse);
    });

    test('strength follows legacy tiers', () {
      expect(passwordStrength(null), PasswordStrength.weak);
      expect(passwordStrength(''), PasswordStrength.weak);
      expect(passwordStrength('Abc1!'), PasswordStrength.weak);
      expect(passwordStrength('abcdefghijk'), PasswordStrength.medium);
      expect(passwordStrength('Abcdefghij1!'), PasswordStrength.strong);
    });

    test('wrapper skips empty and accepts custom message', () {
      expect(ValidPassword().validate('Abcdef1!'), isNull);
      expect(ValidPassword().validate('weak'), isNotNull);
      expect(ValidPassword().validate(''), isNull);
      expect(ValidPassword().validate(null), isNull);
      expect(ValidPassword(message: 'custom').validate('weak'), 'custom');
    });
  });

  group('date validation', () {
    test('text follows format and calendar validity', () {
      expect(isValidDateText('15/08/2024'), isTrue);
      expect(isValidDateText('29/02/2024'), isTrue);
      expect(isValidDateText('29/02/2023'), isFalse);
      expect(isValidDateText('31/04/2024'), isFalse);
      expect(isValidDateText('15-08-2024'), isTrue);
      expect(isValidDateText('2024-08-15', format: 'yyyy-MM-dd'), isTrue);
      expect(isValidDateText('15/08/24'), isFalse);
      expect(isValidDateText(null), isFalse);
      expect(isValidDateText(''), isFalse);
    });

    test('year range is configurable', () {
      expect(isValidDateText('15/08/1800'), isFalse);
      expect(
        isValidDateText('15/08/1800', minYear: 1800, maxYear: 2100),
        isTrue,
      );
    });

    test('DateTime overload validates calendar range', () {
      expect(isValidDate(DateTime(2024, 8, 15)), isTrue);
      expect(isValidDate(null), isFalse);
      expect(isValidDate(DateTime(1800, 1, 1)), isFalse);
      expect(
        isValidDate(DateTime(1800, 1, 1), minYear: 1800, maxYear: 2100),
        isTrue,
      );
    });

    test('wrappers skip empty and accept custom message', () {
      expect(ValidDate().validate('15/08/2024'), isNull);
      expect(ValidDate().validate('31/04/2024'), isNotNull);
      expect(ValidDate().validate(''), isNull);
      expect(ValidDate().validate(null), isNull);
      expect(ValidDate(message: 'custom').validate('31/04/2024'), 'custom');

      expect(ValidDateTime().validate(DateTime(2024, 8, 15)), isNull);
      expect(ValidDateTime().validate(DateTime(1800, 1, 1)), isNotNull);
      expect(ValidDateTime().validate(null), isNull);
    });
  });
}

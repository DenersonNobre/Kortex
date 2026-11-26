import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_forms/kortex_forms.dart';

String? _required(String value) =>
    value.trim().isEmpty ? 'Required field' : null;

void main() {
  group('KortexField & KortexForm', () {
    test('tracks dirty, touched, and validation errors', () {
      final email = kortexField<String>('', validators: [_required]);

      expect(email.dirty.value, isFalse);
      expect(email.touched.value, isFalse);
      expect(email.error.value, isNull);
      expect(email.isValid, isFalse);

      expect(email.validate(), isFalse);
      expect(email.touched.value, isTrue);
      expect(email.error.value, 'Required field');

      email.value = 'dev@bonusoft.com.br';
      expect(email.dirty.value, isTrue);
      expect(email.error.value, isNull);
      expect(email.isValid, isTrue);

      email.reset();
      expect(email.value, '');
      expect(email.dirty.value, isFalse);
      expect(email.touched.value, isFalse);
      expect(email.error.value, isNull);

      email.dispose();
    });

    test('reset(null) em campo nullable reseta explicitamente para null', () {
      final notes = kortexField<String?>('inicial');
      notes.value = 'editado';

      notes.reset(null);
      expect(notes.value, isNull);
      expect(notes.dirty.value, isFalse);

      notes.reset();
      expect(notes.value, 'inicial');

      notes.dispose();
    });

    test('KortexForm validates, resets, and disposes all fields', () {
      final name = kortexField<String>('', validators: [_required]);
      final age = kortexField<int>(
        0,
        validators: [(v) => v < 18 ? 'Must be 18+' : null],
      );
      final form = kortexForm([name, age]);

      expect(form.validate(), isFalse);
      expect(name.error.value, 'Required field');
      expect(age.error.value, 'Must be 18+');

      name.value = 'Ana';
      age.value = 25;
      expect(form.validate(), isTrue);
      expect(form.isValid, isTrue);

      form.reset();
      expect(name.value, '');
      expect(age.value, 0);

      form.dispose();
      expect(() => name.value, throwsStateError);
    });

    test('kortexValidator builds reusable fluent validators', () {
      final validateEmail = kortexValidator<String>()
          .required('Email required')
          .email('Invalid email')
          .build();

      expect(validateEmail(''), 'Email required');
      expect(validateEmail('abc'), 'Invalid email');
      expect(validateEmail('dev@bonusoft.com.br'), isNull);

      final field = kortexField<String>('', validators: [validateEmail]);
      expect(field.validate(), isFalse);
      expect(field.error.value, 'Email required');

      field.value = 'dev@bonusoft.com.br';
      expect(field.isValid, isTrue);
      field.dispose();
    });

    test('supports everyday string, numeric, and collection rules', () {
      final urlRule = kortexValidator<String>().url().build();
      expect(urlRule('https://bonusoft.com.br'), isNull);
      expect(urlRule('not-a-url'), 'Invalid URL');

      final codeRule = kortexValidator<String>()
          .numeric()
          .exactLength(6)
          .build();
      expect(codeRule('123456'), isNull);
      expect(codeRule('12ab56'), 'Must contain only digits');

      var password = 'secret';
      final confirmRule = kortexValidator<String>()
          .equals(() => password, 'Passwords do not match')
          .build();
      expect(confirmRule('other'), 'Passwords do not match');
      expect(confirmRule('secret'), isNull);

      final ageRule = kortexValidator<int>().range(18, 120).build();
      expect(ageRule(17), 'Must be between 18 and 120');
      expect(ageRule(30), isNull);

      final tagsRule = kortexValidator<List<String>>()
          .notEmpty()
          .maxItems(2)
          .build();
      expect(tagsRule([]), 'Select at least one item');
      expect(tagsRule(['a', 'b']), isNull);
      expect(tagsRule(['a', 'b', 'c']), 'Select at most 2 items');

      final alphaRule = kortexValidator<String>().alphanumeric().build();
      expect(alphaRule('abc123'), isNull);
      expect(alphaRule('abc-123'), 'Must be alphanumeric');

      final numRule = kortexValidator<num>().min(5).max(10).positive().build();
      expect(numRule(4), 'Must be at least 5');
      expect(numRule(11), 'Must be at most 10');
      expect(numRule(7), isNull);
    });

    test('supports conditional when() and nullable notNull() rules', () {
      var requireTaxId = false;
      final taxIdRule = kortexValidator<String>()
          .when(() => requireTaxId, (r) => r.required().exactLength(11))
          .build();

      expect(taxIdRule(''), isNull);
      requireTaxId = true;
      expect(taxIdRule(''), 'Required field');
      expect(taxIdRule('123'), 'Must be 11 characters');
      expect(taxIdRule('12345678901'), isNull);

      final dateField = kortexField<DateTime?>(
        null,
        validators: [
          kortexValidator<DateTime?>().notNull('Pick a date').build(),
        ],
      );
      expect(dateField.validate(), isFalse);
      expect(dateField.error.value, 'Pick a date');

      dateField.value = DateTime(2026, 11, 23);
      expect(dateField.isValid, isTrue);
      dateField.dispose();
    });
  });
}

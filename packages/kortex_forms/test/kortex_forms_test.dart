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
  });
}

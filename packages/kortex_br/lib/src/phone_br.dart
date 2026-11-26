import 'digits.dart';

/// Brazilian phone validator and formatter (pure Dart).
abstract final class PhoneBrValidator {
  /// Returns `null` when [value] has 10 or 11 digits (with valid DDD), or an error.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Telefone obrigatorio';
    final digits = digitsOnly(value);
    if (digits.length != 10 && digits.length != 11) {
      return 'Telefone deve ter 10 ou 11 digitos';
    }
    final ddd = int.parse(digits.substring(0, 2));
    if (ddd < 11 || ddd > 99) return 'DDD invalido';
    if (digits.length == 11 && digits[2] != '9') {
      return 'Celular deve iniciar com 9';
    }
    return null;
  }

  /// Returns `true` when [value] is a valid Brazilian phone number.
  static bool isValid(String? value) => validate(value) == null;
}

/// Formats a Brazilian phone as `(00) 0000-0000` or `(00) 00000-0000`.
abstract final class PhoneBrFormatter {
  /// Formats [input] into Brazilian phone mask.
  static String format(String input) {
    final d = digitsOnly(input);
    final c = d.length > 11 ? d.substring(0, 11) : d;
    if (c.isEmpty) return '';
    if (c.length <= 2) return '($c';
    if (c.length <= 6) return '(${c.substring(0, 2)}) ${c.substring(2)}';
    if (c.length <= 10) {
      return '(${c.substring(0, 2)}) ${c.substring(2, 6)}-${c.substring(6)}';
    }
    return '(${c.substring(0, 2)}) ${c.substring(2, 7)}-${c.substring(7)}';
  }
}

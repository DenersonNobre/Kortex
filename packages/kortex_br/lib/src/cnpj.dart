import 'digits.dart';

/// Brazilian CNPJ validator and formatter (pure Dart).
abstract final class CnpjValidator {
  static const _weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  static const _weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  /// Returns `null` when [value] is a valid CNPJ, or an error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'CNPJ obrigatorio';
    final digits = digitsOnly(value);
    if (digits.length != 14) return 'CNPJ deve ter 14 digitos';
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return 'CNPJ invalido';
    }
    final d1 = _checkDigit(digits.substring(0, 12), _weights1);
    final d2 = _checkDigit(digits.substring(0, 13), _weights2);
    if (d1 != int.parse(digits[12]) || d2 != int.parse(digits[13])) {
      return 'CNPJ invalido';
    }
    return null;
  }

  /// Returns `true` when [value] is a valid CNPJ.
  static bool isValid(String? value) => validate(value) == null;

  static int _checkDigit(String slice, List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += int.parse(slice[i]) * weights[i];
    }
    final rem = sum % 11;
    return rem < 2 ? 0 : 11 - rem;
  }
}

/// Formats a CNPJ string as `00.000.000/0000-00`.
abstract final class CnpjFormatter {
  /// Formats [input] into `00.000.000/0000-00` (or partial while typing).
  static String format(String input) {
    final d = digitsOnly(input);
    final c = d.length > 14 ? d.substring(0, 14) : d;
    if (c.length <= 2) return c;
    if (c.length <= 5) return '${c.substring(0, 2)}.${c.substring(2)}';
    if (c.length <= 8) {
      return '${c.substring(0, 2)}.${c.substring(2, 5)}.${c.substring(5)}';
    }
    if (c.length <= 12) {
      return '${c.substring(0, 2)}.${c.substring(2, 5)}.${c.substring(5, 8)}/${c.substring(8)}';
    }
    return '${c.substring(0, 2)}.${c.substring(2, 5)}.${c.substring(5, 8)}/${c.substring(8, 12)}-${c.substring(12)}';
  }
}

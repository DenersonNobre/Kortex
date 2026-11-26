import 'digits.dart';

/// Brazilian CPF validator and formatter (pure Dart).
abstract final class CpfValidator {
  /// Returns `null` when [value] is a valid CPF, or an error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'CPF obrigatorio';
    final digits = digitsOnly(value);
    if (digits.length != 11) return 'CPF deve ter 11 digitos';
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return 'CPF invalido';
    }
    final d1 = _checkDigit(digits.substring(0, 9), 10);
    final d2 = _checkDigit(digits.substring(0, 10), 11);
    if (d1 != int.parse(digits[9]) || d2 != int.parse(digits[10])) {
      return 'CPF invalido';
    }
    return null;
  }

  /// Returns `true` when [value] is a valid CPF.
  static bool isValid(String? value) => validate(value) == null;

  static int _checkDigit(String slice, int startWeight) {
    var sum = 0;
    for (var i = 0; i < slice.length; i++) {
      sum += int.parse(slice[i]) * (startWeight - i);
    }
    final rem = (sum * 10) % 11;
    return rem == 10 ? 0 : rem;
  }
}

/// Formats a CPF string as `000.000.000-00`.
abstract final class CpfFormatter {
  /// Formats [input] into `000.000.000-00` when 11 digits are present,
  /// or partially as typed.
  static String format(String input) {
    final d = digitsOnly(input);
    final clipped = d.length > 11 ? d.substring(0, 11) : d;
    if (clipped.length <= 3) return clipped;
    if (clipped.length <= 6) {
      return '${clipped.substring(0, 3)}.${clipped.substring(3)}';
    }
    if (clipped.length <= 9) {
      return '${clipped.substring(0, 3)}.${clipped.substring(3, 6)}.${clipped.substring(6)}';
    }
    return '${clipped.substring(0, 3)}.${clipped.substring(3, 6)}.${clipped.substring(6, 9)}-${clipped.substring(9)}';
  }
}

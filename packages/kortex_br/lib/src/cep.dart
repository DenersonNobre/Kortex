import 'digits.dart';

/// Brazilian CEP validator and formatter (pure Dart).
abstract final class CepValidator {
  /// Returns `null` when [value] has 8 digits, or an error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'CEP obrigatorio';
    final digits = digitsOnly(value);
    if (digits.length != 8) return 'CEP deve ter 8 digitos';
    return null;
  }

  /// Returns `true` when [value] is a valid CEP.
  static bool isValid(String? value) => validate(value) == null;
}

/// Formats a CEP string as `00000-000`.
abstract final class CepFormatter {
  /// Formats [input] into `00000-000` (or partial while typing).
  static String format(String input) {
    final d = digitsOnly(input);
    final c = d.length > 8 ? d.substring(0, 8) : d;
    if (c.length <= 5) return c;
    return '${c.substring(0, 5)}-${c.substring(5)}';
  }
}

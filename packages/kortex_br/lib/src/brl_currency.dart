import 'digits.dart';

/// Formats and parses Brazilian Real (BRL) values in integer cents.
abstract final class BrlCurrencyFormatter {
  /// Formats [cents] as `R$ 1.234,56` (or `-R$ 1.234,56` when negative).
  static String formatCents(int cents) {
    final isNegative = cents < 0;
    final absCents = cents.abs();
    final reais = (absCents ~/ 100).toString();
    final centavos = (absCents % 100).toString().padLeft(2, '0');
    final buffer = StringBuffer();
    for (var i = 0; i < reais.length; i++) {
      final remaining = reais.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(reais[i]);
    }
    final prefix = isNegative ? '-R\$ ' : 'R\$ ';
    return '$prefix$buffer,$centavos';
  }

  /// Parses a BRL string (e.g. `R$ 1.234,56`) into integer cents, or `null`.
  static int? parseToCents(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final isNegative = input.contains('-');
    final digits = digitsOnly(input);
    if (digits.isEmpty) return null;
    final cents = int.parse(digits);
    return isNegative ? -cents : cents;
  }
}

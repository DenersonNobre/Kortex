import 'validator_utils.dart';

/// Valida CPF verificando formato e dígitos verificadores.
class CpfValidator {
  const CpfValidator._();

  static bool isValid(String? source) {
    final digits = normalize(source, allowLetters: false);
    if (digits == null || digits.length != 11 || hasRepeatedChars(digits)) {
      return false;
    }

    final first = cpfDigit(digits.substring(0, 9));
    if (first != int.parse(digits[9])) {
      return false;
    }

    final second = cpfDigit(digits.substring(0, 10));
    return second == int.parse(digits[10]);
  }

  /// Retorna `null` quando válido ou [message] quando inválido (compatível com `KortexField` e `TextFormField`).
  static String? validate(String? source, [String message = 'CPF inválido']) =>
      isValid(source) ? null : message;
}

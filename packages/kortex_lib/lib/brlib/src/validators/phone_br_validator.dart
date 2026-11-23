import 'validator_utils.dart';

/// Verifica telefone brasileiro pelo formato nacional de dez ou onze dígitos.
class PhoneBrValidator {
  const PhoneBrValidator._();

  static bool hasValidShape(String? source) {
    final digits = normalize(source, allowLetters: false);
    return digits != null && (digits.length == 10 || digits.length == 11);
  }
}

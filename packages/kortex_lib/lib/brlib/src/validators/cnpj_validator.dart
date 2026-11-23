import 'validator_utils.dart';

/// Valida CNPJ numérico e alfanumérico pelo módulo 11.
class CnpjValidator {
  const CnpjValidator._();

  static const _firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  static const _secondWeights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  static bool isValid(String? source) {
    final normalized = normalize(source, allowLetters: true);
    if (normalized == null ||
        normalized.length != 14 ||
        hasRepeatedChars(normalized) ||
        !isDigits(normalized.substring(12))) {
      return false;
    }

    final base = normalized.substring(0, 12);
    final first = _cnpjDigit(base, _firstWeights);
    if (first != int.parse(normalized[12])) {
      return false;
    }

    final second = _cnpjDigit('$base$first', _secondWeights);
    return second == int.parse(normalized[13]);
  }

  static int _cnpjDigit(String value, List<int> weights) {
    var sum = 0;
    for (var index = 0; index < weights.length; index++) {
      sum += _cnpjValue(value.codeUnitAt(index)) * weights[index];
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  // A especificação da Receita Federal usa o código ASCII menos 48.
  static int _cnpjValue(int codeUnit) => codeUnit - 48;
}

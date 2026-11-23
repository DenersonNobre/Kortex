import 'validator_utils.dart';

/// Valida formato e integridade básica de CEP brasileiro.
///
/// Não consulta a existência do endereço nos Correios.
class CepValidator {
  const CepValidator._();

  /// Verifica se o CEP possui formato básico de 8 dígitos numéricos.
  static bool hasValidShape(String? source) {
    final digits = normalize(source, allowLetters: false);
    return digits != null && digits.length == 8;
  }

  /// Valida o CEP verificando se possui 8 dígitos e rejeitando sequências
  /// de dígitos repetidos (ex.: `11111111`, `00000000`).
  static bool isValid(String? source) {
    final digits = normalize(source, allowLetters: false);
    if (digits == null || digits.length != 8) {
      return false;
    }
    // Rejeita sequências de dígitos todos iguais
    if (hasRepeatedChars(digits)) {
      return false;
    }
    return true;
  }

  /// Retorna mensagem de erro para uso em formulários ou `null` se válido.
  /// Se [obrigatorio] for false e a entrada for vazia/nula, retorna `null`.
  static String? validate(String? source, {bool obrigatorio = false}) {
    final digits = normalize(source, allowLetters: false) ?? '';
    if (digits.isEmpty) {
      return obrigatorio ? 'CEP obrigatório' : null;
    }
    if (!isValid(digits)) {
      return 'CEP inválido';
    }
    return null;
  }
}

/// Valida siglas das unidades federativas brasileiras.
class UfValidator {
  const UfValidator._();

  static const Set<String> _ufs = {
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  };

  static bool isValid(String? source) =>
      source != null && _ufs.contains(source.trim().toUpperCase());

  /// Retorna `null` quando válido ou [message] quando inválido.
  static String? validate(String? source, [String message = 'UF inválida']) =>
      isValid(source) ? null : message;
}

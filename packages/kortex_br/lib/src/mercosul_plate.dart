/// Brazilian Mercosul vehicle plate validator (`AAA0A00`).
abstract final class MercosulPlateValidator {
  static final _plateRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');

  /// Returns `null` when [value] matches Mercosul format, or an error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Placa obrigatoria';
    final normalized = value.trim().toUpperCase().replaceAll('-', '');
    if (!_plateRegex.hasMatch(normalized)) return 'Placa Mercosul invalida';
    return null;
  }

  /// Returns `true` when [value] is a valid Mercosul plate.
  static bool isValid(String? value) => validate(value) == null;
}

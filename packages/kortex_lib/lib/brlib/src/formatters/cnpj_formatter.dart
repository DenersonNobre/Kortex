import 'mask_utils.dart';

/// Formata CNPJ numérico ou alfanumérico completo.
String formatCnpj(String source) {
  final normalized = extract(source, RegExp(r'^[A-Z0-9.()\-/\s]+$'));
  if (normalized == null ||
      normalized.length != 14 ||
      !RegExp(r'^[0-9]{2}$').hasMatch(normalized.substring(12))) {
    return source;
  }
  return applyMask(normalized, 'AA.AAA.AAA/AAAA-##', allowLetters: true);
}

import 'mask_utils.dart';

/// Formata telefone com DDD informado e sem presumir um DDD padrão.
String formatPhoneBr(String source) {
  final normalized = extract(source, RegExp(r'^[0-9()+\-\s]+$'));
  if (normalized == null ||
      (normalized.length != 10 && normalized.length != 11)) {
    return source;
  }
  final mask = normalized.length == 10 ? '(##) ####-####' : '(##) #####-####';
  return applyMask(normalized, mask, allowLetters: false);
}

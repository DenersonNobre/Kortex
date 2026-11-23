import 'validators.dart';

// Practical shape check (HTML5-inspired): local part allows RFC 5322
// atext + '+', domain labels are alphanumeric with optional hyphens,
// TLD is 2+ alpha chars (no artificial 7-char ceiling).
final RegExp _emailPattern = RegExp(
  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
  r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?'
  r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)+$',
);

/// Pure email-shape check, without Flutter or locale dependencies.
///
/// Returns false for null or empty input. The [ValidEmail] wrapper treats
/// empty as absent (optional field) so it composes with [NotEmpty].
bool isValidEmail(String? value) {
  if (value == null || value.isEmpty) {
    return false;
  }
  return _emailPattern.hasMatch(value);
}

/// Optional-field email validator: empty passes, malformed fails.
///
/// Pair with [NotEmpty] when the field is required.
class ValidEmail extends Validator<String?> {
  ValidEmail({String? message})
    : super((value) {
        if (value == null || value.isEmpty) {
          return null;
        }
        if (isValidEmail(value)) {
          return null;
        }
        return message ?? 'Endereço de e-mail inválido';
      });
}

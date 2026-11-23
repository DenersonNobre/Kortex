import 'validators.dart';

/// Neutral password strength tiers, without UI or locale dependencies.
enum PasswordStrength { weak, medium, strong }

/// Configurable password policy: algorithm and thresholds are injectable,
/// messages stay with the caller via [ValidPassword].
class PasswordPolicy {
  const PasswordPolicy({
    this.minLength = 8,
    this.requireLetter = true,
    this.requireDigit = true,
    this.requireSymbol = true,
    this.requireUppercase = false,
    this.requireLowercase = false,
    this.strongLength = 11,
  });

  final int minLength;
  final bool requireLetter;
  final bool requireDigit;
  final bool requireSymbol;
  final bool requireUppercase;
  final bool requireLowercase;

  /// Length above which a categorized password counts as strong.
  final int strongLength;

  static final RegExp _letter = RegExp(r'[a-zA-Z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  // Any non-alphanumeric char counts as symbol — same semantic as
  // passwordStrength below; the old ASCII whitelist rejected valid
  // symbols like ~ + [ / ' _ -.
  static final RegExp _symbol = RegExp(r'[^a-zA-Z0-9]');
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');

  bool isSatisfiedBy(String? password) {
    if (password == null || password.length < minLength) {
      return false;
    }
    if (requireLetter && !_letter.hasMatch(password)) {
      return false;
    }
    if (requireDigit && !_digit.hasMatch(password)) {
      return false;
    }
    if (requireSymbol && !_symbol.hasMatch(password)) {
      return false;
    }
    if (requireUppercase && !_upper.hasMatch(password)) {
      return false;
    }
    if (requireLowercase && !_lower.hasMatch(password)) {
      return false;
    }
    return true;
  }
}

/// Legacy-compatible strength tiers over raw character categories.
///
/// Weak covers short passwords; strong requires a letter family plus a
/// digit or symbol once past [PasswordPolicy.strongLength].
PasswordStrength passwordStrength(String? password, {int strongLength = 11}) {
  if (password == null || password.isEmpty || password.length < strongLength) {
    return PasswordStrength.weak;
  }

  var hasLower = false;
  var hasUpper = false;
  var hasDigit = false;
  var hasSymbol = false;
  for (var i = 0; i < password.length; i++) {
    final code = password.codeUnitAt(i);
    if (code >= 48 && code <= 57) {
      hasDigit = true;
    } else if (code >= 65 && code <= 90) {
      hasUpper = true;
    } else if (code >= 97 && code <= 122) {
      hasLower = true;
    } else {
      hasSymbol = true;
    }
  }

  if ((hasLower || hasUpper) && (hasDigit || hasSymbol)) {
    return PasswordStrength.strong;
  }
  return PasswordStrength.medium;
}

/// Optional-field password validator driven by an injectable [policy].
class ValidPassword extends Validator<String?> {
  ValidPassword({this.policy = const PasswordPolicy(), String? message})
    : super((value) {
        if (value == null || value.isEmpty) {
          return null;
        }
        if (policy.isSatisfiedBy(value)) {
          return null;
        }
        return message ?? 'A senha não atende à política exigida.';
      });

  final PasswordPolicy policy;
}

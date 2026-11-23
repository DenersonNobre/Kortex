import 'package:kortex_forms/src/kortex_field.dart';

/// Fluent builder producing a composable [KortexValidator] function.
class KortexValidatorBuilder<T> {
  final List<KortexValidator<T>> _rules = [];

  /// Adds a custom [predicate] returning [message] when it evaluates to `false`.
  KortexValidatorBuilder<T> must(
    bool Function(T value) predicate,
    String message,
  ) {
    _rules.add((value) => predicate(value) ? null : message);
    return this;
  }

  /// Appends an existing [validator] to the chain.
  KortexValidatorBuilder<T> use(KortexValidator<T> validator) {
    _rules.add(validator);
    return this;
  }

  /// Builds a single [KortexValidator] running all rules in registration order.
  KortexValidator<T> build() {
    final snapshot = List<KortexValidator<T>>.unmodifiable(_rules);
    return (value) {
      for (final rule in snapshot) {
        final error = rule(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

/// String-specific fluent validation helpers for [KortexValidatorBuilder].
extension KortexStringValidatorBuilder on KortexValidatorBuilder<String> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Fails when the trimmed string is empty.
  KortexValidatorBuilder<String> required([
    String message = 'Required field',
  ]) => must((v) => v.trim().isNotEmpty, message);

  /// Fails when `value.length < min`.
  KortexValidatorBuilder<String> minLength(int min, [String? message]) =>
      must((v) => v.length >= min, message ?? 'Minimum $min characters');

  /// Fails when `value.length > max`.
  KortexValidatorBuilder<String> maxLength(int max, [String? message]) =>
      must((v) => v.length <= max, message ?? 'Maximum $max characters');

  /// Fails when the value does not match a basic email format.
  KortexValidatorBuilder<String> email([String message = 'Invalid email']) =>
      must((v) => _emailRegex.hasMatch(v.trim()), message);

  /// Fails when the value does not match [regex].
  KortexValidatorBuilder<String> pattern(RegExp regex, String message) =>
      must((v) => regex.hasMatch(v), message);
}

/// Creates a fluent [KortexValidatorBuilder] for type [T].
KortexValidatorBuilder<T> kortexValidator<T>() => KortexValidatorBuilder<T>();

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
  static final _numericRegex = RegExp(r'^\d+$');
  static final _alnumRegex = RegExp(r'^[a-zA-Z0-9]+$');

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

  /// Fails when `value.length != length`.
  KortexValidatorBuilder<String> exactLength(int length, [String? message]) =>
      must((v) => v.length == length, message ?? 'Must be $length characters');

  /// Fails when the value does not match a basic email format.
  KortexValidatorBuilder<String> email([String message = 'Invalid email']) =>
      must((v) => _emailRegex.hasMatch(v.trim()), message);

  /// Fails when the value is not a valid `http` or `https` URL.
  KortexValidatorBuilder<String> url([String message = 'Invalid URL']) =>
      must((v) {
        final uri = Uri.tryParse(v.trim());
        return uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
      }, message);

  /// Fails when the value contains non-digit characters.
  KortexValidatorBuilder<String> numeric([
    String message = 'Must contain only digits',
  ]) => must((v) => _numericRegex.hasMatch(v), message);

  /// Fails when the value contains non-alphanumeric characters.
  KortexValidatorBuilder<String> alphanumeric([
    String message = 'Must be alphanumeric',
  ]) => must((v) => _alnumRegex.hasMatch(v), message);

  /// Fails when the value does not match [expected] (useful for password confirmation).
  KortexValidatorBuilder<String> equals(
    String Function() expected, [
    String message = 'Values do not match',
  ]) => must((v) => v == expected(), message);

  /// Fails when the value does not match [regex].
  KortexValidatorBuilder<String> pattern(RegExp regex, String message) =>
      must((v) => regex.hasMatch(v), message);
}

/// Numeric fluent validation helpers for [KortexValidatorBuilder].
extension KortexNumValidatorBuilder<T extends num>
    on KortexValidatorBuilder<T> {
  /// Fails when `value < min`.
  KortexValidatorBuilder<T> min(T min, [String? message]) =>
      must((v) => v >= min, message ?? 'Must be at least $min');

  /// Fails when `value > max`.
  KortexValidatorBuilder<T> max(T max, [String? message]) =>
      must((v) => v <= max, message ?? 'Must be at most $max');

  /// Fails when `value < min || value > max`.
  KortexValidatorBuilder<T> range(T min, T max, [String? message]) => must(
    (v) => v >= min && v <= max,
    message ?? 'Must be between $min and $max',
  );

  /// Fails when `value <= 0`.
  KortexValidatorBuilder<T> positive([
    String message = 'Must be greater than zero',
  ]) => must((v) => v > 0, message);
}

/// Collection fluent validation helpers for [KortexValidatorBuilder].
extension KortexIterableValidatorBuilder<E, T extends Iterable<E>>
    on KortexValidatorBuilder<T> {
  /// Fails when the collection is empty.
  KortexValidatorBuilder<T> notEmpty([
    String message = 'Select at least one item',
  ]) => must((v) => v.isNotEmpty, message);

  /// Fails when `value.length < min`.
  KortexValidatorBuilder<T> minItems(int min, [String? message]) =>
      must((v) => v.length >= min, message ?? 'Select at least $min items');

  /// Fails when `value.length > max`.
  KortexValidatorBuilder<T> maxItems(int max, [String? message]) =>
      must((v) => v.length <= max, message ?? 'Select at most $max items');
}

/// Creates a fluent [KortexValidatorBuilder] for type [T].
KortexValidatorBuilder<T> kortexValidator<T>() => KortexValidatorBuilder<T>();

/// Short alias for [KortexValidator].
typedef KortexRule<T> = KortexValidator<T>;

/// Short alias for [KortexValidatorBuilder].
typedef KortexRules<T> = KortexValidatorBuilder<T>;

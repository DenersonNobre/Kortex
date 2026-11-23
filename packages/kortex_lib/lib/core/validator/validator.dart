import 'validators.dart' show Validator;

class Rule<T, TValue> {
  final String key;
  final TValue Function(T) selector;
  final List<Validator<TValue?>> validations = [];

  Rule(this.selector, this.key);

  Rule<T, TValue> addValidation(Validator<TValue?> validator) {
    validations.add(validator);
    return this;
  }

  List<String> validate(T entity) {
    final value = selector(entity);
    return validations
        .map((validator) => validator.validate(value) ?? '')
        .where((error) => error.isNotEmpty)
        .toList();
  }
}

abstract class ICustomValidator<T> {
  final List<String> errors = [];
  final List<Rule<T, dynamic>> _rules = [];

  Rule<T, R> ruleFor<R>(R Function(T) selector, {required String key}) {
    final rule = Rule<T, R>(selector, key);
    _rules.add(rule);
    return rule;
  }

  String? Function(String?) byField(T entity, String key) {
    return (String? value) => validateField(entity, key);
  }

  String? validateField(T entity, String key) {
    final rule = _rules.firstWhere((rule) => rule.key == key);
    final errors = rule.validate(entity);
    return errors.isEmpty ? null : errors.first;
  }

  List<String> validate(T entity) {
    errors.clear();
    for (final rule in _rules) {
      errors.addAll(rule.validate(entity));
    }
    return errors;
  }
}

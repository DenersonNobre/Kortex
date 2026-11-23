class Validator<T> {
  final String? Function(T) validate;

  Validator(this.validate);
}

class NotEmpty extends Validator<String?> {
  NotEmpty({String? message})
    : super(
        (value) =>
            (value ?? '').isEmpty ? message ?? 'Não pode estar vazio' : null,
      );
}

class MinLength extends Validator<String?> {
  MinLength({required int length, String? message})
    : super(
        (value) => (value ?? '').length < length
            ? message ?? 'Deve ter no mínimo $length caracteres'
            : null,
      );
}

class MaxLength extends Validator<String?> {
  MaxLength({required int length, String? message})
    : super(
        (value) => (value ?? '').length > length
            ? message ?? 'Deve ter no máximo $length caracteres'
            : null,
      );
}

class Regex extends Validator<String?> {
  Regex({required RegExp regExp, String? message})
    : super(
        (value) => !regExp.hasMatch(value ?? '')
            ? message ?? 'Deve corresponder ao padrão $regExp'
            : null,
      );
}

class GreaterThanZero<T extends num> extends Validator<T?> {
  GreaterThanZero({String? message})
    : super(
        (value) =>
            (value ?? 0) <= 0 ? message ?? 'Deve ser maior que zero' : null,
      );
}

class GreaterThan<T extends num> extends Validator<T?> {
  GreaterThan({required num value, String? message})
    : super(
        (candidate) => (candidate ?? 0) <= value
            ? message ?? 'Deve ser maior que $value'
            : null,
      );
}

class LessThan extends Validator<num?> {
  LessThan({required num value, String? message})
    : super(
        (candidate) => (candidate ?? 0) >= value
            ? message ?? 'Deve ser menor que $value'
            : null,
      );
}

class Range extends Validator<num?> {
  Range({required num min, required num max, String? message})
    : super(
        (value) => (value ?? 0) < min || (value ?? 0) > max
            ? message ?? 'Deve estar entre $min e $max'
            : null,
      );
}

class EqualTo extends Validator<String?> {
  EqualTo({required String value, String? message})
    : super(
        (candidate) =>
            candidate != value ? message ?? 'Deve ser igual a $value' : null,
      );
}

class DifferentFrom extends Validator<String?> {
  DifferentFrom({required String value, String? message})
    : super(
        (candidate) => candidate == value
            ? message ?? 'Deve ser diferente de $value'
            : null,
      );
}

class NotZero<T extends num> extends Validator<T?> {
  NotZero({String? message})
    : super(
        (value) => (value ?? 0) == 0 ? message ?? 'Não pode ser zero' : null,
      );
}

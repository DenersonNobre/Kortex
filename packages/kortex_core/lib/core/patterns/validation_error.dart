import 'result.dart' show IFailure;

class ValidationError extends IFailure {
  const ValidationError({
    required super.code,
    required super.message,
    super.details,
  });
}

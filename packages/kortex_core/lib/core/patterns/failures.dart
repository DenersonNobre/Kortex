import 'result.dart' show IFailure;

export 'result.dart' show IFailure;

/// Constantes nominais para códigos de falha padronizados (elimina strings mágicas).
abstract final class FailureCode {
  static const validation = 'VALIDATION_ERROR';
  static const notFound = 'NOT_FOUND';
  static const unauthorized = 'UNAUTHORIZED';
  static const conflict = 'CONFLICT';
  static const infrastructure = 'INFRASTRUCTURE_ERROR';
  static const unexpected = 'UNEXPECTED_ERROR';
}

/// Falha de validação de dados de entrada ou invariante de negócio.
class ValidationFailure extends IFailure {
  const ValidationFailure(String message, [Object? details])
    : super(code: FailureCode.validation, message: message, details: details);
}

/// Falha quando uma entidade/recurso não é encontrado.
class NotFoundFailure extends IFailure {
  const NotFoundFailure(String message, [Object? details])
    : super(code: FailureCode.notFound, message: message, details: details);
}

/// Falha de autorização ou autenticação.
class UnauthorizedFailure extends IFailure {
  const UnauthorizedFailure(String message, [Object? details])
    : super(code: FailureCode.unauthorized, message: message, details: details);
}

/// Falha de conflito (duplicidade, violação de unicidade ou concorrência).
class ConflictFailure extends IFailure {
  const ConflictFailure(String message, [Object? details])
    : super(code: FailureCode.conflict, message: message, details: details);
}

/// Falha de infraestrutura (banco de dados, rede, filesystem).
class InfrastructureFailure extends IFailure {
  const InfrastructureFailure(String message, [Object? details])
    : super(
        code: FailureCode.infrastructure,
        message: message,
        details: details,
      );
}

/// Falha decorrente de exceção não tratada ou erro inesperado em runtime.
///
/// Encapsula a causa raiz [error] e o [stackTrace] de forma tipada, sem
/// depender de chaves mágicas em mapas soltos.
final class UnexpectedFailure extends IFailure {
  UnexpectedFailure({
    required this.error,
    required this.stackTrace,
    String? message,
  }) : super(
         code: FailureCode.unexpected,
         message: message ?? error.toString(),
         details: error,
       );

  final Object error;
  final StackTrace stackTrace;

  @override
  Map<String, Object?> toMap() => {
    'code': code,
    'message': message,
    'error': error.toString(),
    'stackTrace': stackTrace.toString(),
  };
}

import 'package:kortex_core/kortex_core.dart';

/// Exemplo didático de `IResult<TSuccess, TFailure>` no `kortex_core`.
void main() {
  final result = _divide(10, 2);

  final message = result.fold(
    onSuccess: (value) => 'Resultado: $value',
    onFailure: (error) => 'Erro: $error',
  );
  print(message);
}

IResult<int, String> _divide(int a, int b) {
  if (b == 0) {
    return const Failure('Divisao por zero nao permitida');
  }
  return Success(a ~/ b);
}

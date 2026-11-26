import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Result Extensions', () {
    test('T.toSuccess() envelopa valor em Success', () {
      final IResult<int, IFailure> result = 42.toSuccess();
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), 42);
    });

    test('IFailure.toFailure() envelopa falha em Failure', () {
      const failure = ValidationFailure('Erro de teste');
      final IResult<int, ValidationFailure> result = failure.toFailure<int>();
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure(), same(failure));
    });
  });
}

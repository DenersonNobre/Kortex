import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  test('ValidationError is an IFailure usable by IResult.failure', () {
    const error = ValidationError(
      code: 'INVALID_INPUT',
      message: 'Input is invalid.',
    );

    final result = Failure(error);

    expect(error, isA<IFailure>());
    expect(result.getOrNullFailure(), same(error));
  });
}

import 'package:kortex_core/kortex_core.dart';
import 'package:test/test.dart';

class _DoubleUseCase implements IUseCase<int, int> {
  @override
  Future<int> call(int input) async => input * 2;
}

class _PingUseCase implements IUseCaseNoInput<String> {
  @override
  Future<String> call() async => 'pong';
}

void main() {
  group('IUseCase', () {
    test('executes typed input and no-input use cases', () async {
      final doubleUc = _DoubleUseCase();
      final pingUc = _PingUseCase();

      expect(await doubleUc(21), 42);
      expect(await pingUc(), 'pong');
    });
  });
}

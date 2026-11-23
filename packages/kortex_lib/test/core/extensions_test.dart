import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Result and Command Extensions (Red Test)', () {
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

    test('CommandAction.toCommand() cria Command funcional', () async {
      Future<IResult<int, String>> dobro(int? n) async =>
          ((n ?? 0) * 2).toSuccess();

      final command = dobro.toCommand(mapException: (e, _) => e.toString());
      final result = await command.execute(10);

      expect(result?.getOrNull(), 20);
      expect(command.result.value?.getOrNull(), 20);

      var sucessoChamado = false;
      command.whenSuccess((valor) {
        sucessoChamado = true;
        expect(valor, 20);
      });
      expect(sucessoChamado, isTrue);

      command.dispose();
    });

    test(
      'Future<IResult> Function().toCommand() cria Command sem parametros',
      () async {
        Future<IResult<String, String>> obterNome() async => 'DNO'.toSuccess();

        final command = obterNome.toCommand(
          mapException: (e, _) => e.toString(),
        );
        final result = await command.execute();

        expect(result?.getOrNull(), 'DNO');
        command.dispose();
      },
    );
  });
}

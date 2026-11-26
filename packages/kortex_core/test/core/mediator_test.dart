import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

class _ColleagueA {}

class _ColleagueB {}

class _PingCommand implements IRequest<String> {
  final String payload;
  const _PingCommand(this.payload);
}

class _SomaCommand implements IRequest<int> {
  final int a;
  final int b;
  const _SomaCommand(this.a, this.b);
}

class _SomaHandler implements IRequestHandler<_SomaCommand, int> {
  @override
  Future<int> handle(_SomaCommand request) async => request.a + request.b;
}

class _FailCommand implements IRequest<bool> {}

class _PingEspecialCommand extends _PingCommand {
  const _PingEspecialCommand(super.payload);
}

void main() {
  group('Mediator (GoF Mediator - Notificacoes)', () {
    test('roteia mensagem para o handler do par registrado', () {
      final med = Mediator();
      final recebidos = <String>[];
      final token = med.on<_ColleagueA, String>(recebidos.add);

      med.notify<_ColleagueA, String>('oi');

      token();
      expect(recebidos, ['oi']);
    });

    test('nao roteia para pares diferentes do registro', () {
      final med = Mediator();
      final recebidos = <String>[];
      final token = med.on<_ColleagueA, String>(recebidos.add);

      med.notify<_ColleagueB, String>('amigo errado');
      med.notify<_ColleagueA, int>(1);

      token();
      expect(recebidos, isEmpty);
    });

    test('token desfaz o registro', () {
      final med = Mediator();
      final recebidos = <String>[];
      final token = med.on<_ColleagueA, String>(recebidos.add);
      token();

      med.notify<_ColleagueA, String>('depois do token');

      expect(recebidos, isEmpty);
    });

    test('multiplos handlers do mesmo par rodam', () {
      final med = Mediator();
      final a = <String>[];
      final b = <String>[];
      final ta = med.on<_ColleagueA, String>(a.add);
      final tb = med.on<_ColleagueA, String>(b.add);

      med.notify<_ColleagueA, String>('x');

      ta();
      tb();
      expect(a, ['x']);
      expect(b, ['x']);
    });

    test('notify sem registro nao quebra', () {
      final med = Mediator();
      expect(() => med.notify<_ColleagueA, String>('nada'), returnsNormally);
    });

    test('dispose descarta todos os registros', () {
      final med = Mediator();
      final recebidos = <String>[];
      final token = med.on<_ColleagueA, String>(recebidos.add);

      med.dispose();
      med.notify<_ColleagueA, String>('pos-dispose');

      token();
      expect(recebidos, isEmpty);
    });
  });

  group('Mediator (Request-Response Dispatcher)', () {
    test(
      'send despacha IRequest para funcao handler registrada via register',
      () async {
        final med = Mediator();
        med.register<_PingCommand, String>(
          (cmd) async => 'PONG: ${cmd.payload}',
        );

        final resposta = await med.send(_PingCommand('teste'));

        expect(resposta, equals('PONG: teste'));
      },
    );

    test(
      'send despacha IRequest para IRequestHandler registrado via registerHandler',
      () async {
        final med = Mediator();
        med.registerHandler(_SomaHandler());

        final resposta = await med.send(_SomaCommand(10, 32));

        expect(resposta, equals(42));
      },
    );

    test(
      'send lanca StateError se nenhum handler estiver registrado',
      () async {
        final med = Mediator();

        expect(
          () => med.send(_FailCommand()),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'Nenhum handler registrado no Mediator para _FailCommand',
              ),
            ),
          ),
        );
      },
    );

    test('unregister remove o handler registrado', () async {
      final med = Mediator();
      med.registerHandler(_SomaHandler());

      med.unregister<_SomaCommand>();

      expect(() => med.send(_SomaCommand(1, 2)), throwsA(isA<StateError>()));
    });

    test(
      'send usa tipo concreto exato: subclasse nao herda handler da base',
      () async {
        final med = Mediator();
        med.register<_PingCommand, String>(
          (cmd) async => 'PONG: ${cmd.payload}',
        );

        expect(
          () => med.send(const _PingEspecialCommand('x')),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('subclasse com registro proprio despacha normalmente', () async {
      final med = Mediator();
      med.register<_PingCommand, String>((cmd) async => 'PONG: ${cmd.payload}');
      med.register<_PingEspecialCommand, String>(
        (cmd) async => 'ESPECIAL: ${cmd.payload}',
      );

      expect(
        await med.send(const _PingEspecialCommand('x')),
        equals('ESPECIAL: x'),
      );
      expect(await med.send(_PingCommand('y')), equals('PONG: y'));
    });

    test('dispose limpa request handlers alem de notificacoes', () async {
      final med = Mediator();
      med.registerHandler(_SomaHandler());

      med.dispose();

      expect(() => med.send(_SomaCommand(1, 2)), throwsA(isA<StateError>()));
    });
  });
}

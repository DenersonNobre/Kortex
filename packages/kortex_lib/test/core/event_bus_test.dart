import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('EventBus (GoF Observer)', () {
    test('emite e entrega para assinante do mesmo tipo', () async {
      final bus = EventBus();
      final recebidos = <String>[];
      final sub = bus.on<String>(recebidos.add);

      bus.emit('olá');
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(recebidos, ['olá']);
    });

    test('múltiplos assinantes recebem o mesmo evento', () async {
      final bus = EventBus();
      final a = <String>[];
      final b = <String>[];
      final subA = bus.on<String>(a.add);
      final subB = bus.on<String>(b.add);

      bus.emit('x');
      await Future<void>.delayed(Duration.zero);

      await Future.wait([subA.cancel(), subB.cancel()]);
      expect(a, ['x']);
      expect(b, ['x']);
    });

    test('tipos diferentes não cruzam', () async {
      final bus = EventBus();
      final nos = <int>[];
      final sub = bus.on<int>(nos.add);

      bus.emit<String>('sou texto');
      bus.emit(7);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(nos, [7]);
    });

    test('cancel da subscrição remove o ouvinte', () async {
      final bus = EventBus();
      final recebidos = <String>[];
      final sub = bus.on<String>(recebidos.add);
      await sub.cancel();

      bus.emit('depois');

      expect(recebidos, isEmpty);
    });

    test(
      'broadcast não reprisa eventos emitidos antes da assinatura',
      () async {
        final bus = EventBus();
        bus.emit('antes');

        final recebidos = <String>[];
        final sub = bus.on<String>(recebidos.add);

        await sub.cancel();
        expect(recebidos, isEmpty);
      },
    );

    test('emitir sem assinante não quebra', () {
      final bus = EventBus();
      bus.emit('solitário');
      expect(() => bus.emit<int>(1), returnsNormally);
    });

    test('dispose encerra os controllers sem erro', () async {
      final bus = EventBus();
      final recebidos = <String>[];
      final sub = bus.on<String>(recebidos.add);

      bus.dispose();
      await sub.cancel();
      expect(recebidos, isEmpty);
    });
  });
}

import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

enum _Etapa { inicial, validada, concluida }

void main() {
  group('StateMachine', () {
    test('mantém estado inicial e aplica transição permitida', () {
      final maquina = StateMachine<_Etapa>(
        initial: _Etapa.inicial,
        transitions: {(_Etapa.inicial, _Etapa.validada)},
      );

      final resultado = maquina.transitionTo(_Etapa.validada);

      expect(resultado.isSuccess, isTrue);
      expect(resultado.getOrNull(), _Etapa.validada);
      expect(maquina.currentState, _Etapa.validada);
    });

    test('rejeita transição bloqueada sem alterar o estado', () {
      final maquina = StateMachine<_Etapa>(
        initial: _Etapa.inicial,
        transitions: {(_Etapa.inicial, _Etapa.validada)},
      );

      final resultado = maquina.transitionTo(_Etapa.concluida);

      expect(resultado.isFailure, isTrue);
      expect(resultado.getOrNullFailure()?.from, _Etapa.inicial);
      expect(resultado.getOrNullFailure()?.to, _Etapa.concluida);
      expect(maquina.currentState, _Etapa.inicial);
    });

    test('permite qualquer transição quando não há guarda', () {
      final maquina = StateMachine<_Etapa>(initial: _Etapa.inicial);

      expect(maquina.canTransitionTo(_Etapa.concluida), isTrue);
      expect(maquina.transitionTo(_Etapa.concluida).isSuccess, isTrue);
      expect(maquina.currentState, _Etapa.concluida);
    });

    test('permite estado igual somente quando a transição está declarada', () {
      final bloqueada = StateMachine<_Etapa>(
        initial: _Etapa.inicial,
        transitions: {(_Etapa.inicial, _Etapa.validada)},
      );
      final permitida = StateMachine<_Etapa>(
        initial: _Etapa.inicial,
        transitions: {(_Etapa.inicial, _Etapa.inicial)},
      );

      expect(bloqueada.canTransitionTo(_Etapa.inicial), isFalse);
      expect(permitida.transitionTo(_Etapa.inicial).isSuccess, isTrue);
    });

    test('copia a guarda para impedir mutação externa', () {
      final transicoes = <(_Etapa, _Etapa)>{(_Etapa.inicial, _Etapa.validada)};
      final maquina = StateMachine<_Etapa>(
        initial: _Etapa.inicial,
        transitions: transicoes,
      );
      transicoes.clear();

      expect(maquina.canTransitionTo(_Etapa.validada), isTrue);
    });
  });
}

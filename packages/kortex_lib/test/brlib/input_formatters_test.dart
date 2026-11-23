import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/brlib/brlib.dart';

TextEditingValue typing(String text, int cursor) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor),
  );
}

TextEditingValue selecting(String text, int start, int end) {
  return TextEditingValue(
    text: text,
    selection: TextSelection(baseOffset: start, extentOffset: end),
  );
}

void main() {
  group('formatters de documento', () {
    test('CPF remove pontuação existente e mantém o cursor no fim', () {
      final formatter = CpfInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
          text: '529.982.247-25',
          selection: TextSelection.collapsed(offset: 14),
        ),
      );

      expect(result.text, '529.982.247-25');
      expect(result.selection.extentOffset, result.text.length);
    });

    test('CEP limita a oito dígitos e posiciona o cursor após a máscara', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
          text: '0100100099',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );

      expect(result.text, '01001-000');
      expect(result.selection.extentOffset, result.text.length);
    });

    test('CNPJ mantém letras em caixa alta e reserva DV para dígitos', () {
      final formatter = CnpjInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
          text: '12.abc.345/01de-35',
          selection: TextSelection.collapsed(offset: 18),
        ),
      );

      expect(result.text, '12.ABC.345/01DE-35');
      expect(result.selection.extentOffset, result.text.length);
    });

    test('telefone escolhe máscara móvel sem fixar um DDD', () {
      final formatter = PhoneBrInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
          text: '21987654321',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );

      expect(result.text, '(21) 98765-4321');
    });
  });

  group('seleção', () {
    test('CPF substitui a seleção inicial e posiciona após o digitado', () {
      final formatter = CpfInputFormatter();
      final result = formatter.formatEditUpdate(
        selecting('111.111.111-11', 0, 1),
        typing('911.111.111-11', 1),
      );

      expect(result.text, '911.111.111-11');
      expect(result.selection.extentOffset, 1);
    });

    test('CEP remove um intervalo com dígito e separador de uma vez', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        selecting('01001-000', 4, 8),
        typing('01000', 4),
      );

      expect(result.text, '01000');
      expect(result.selection.extentOffset, 4);
    });
  });

  group('edição no meio', () {
    test('CEP insere dígito no meio e mantém o cursor após o digitado', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('01001-000', 3),
        typing('010901-000', 4),
      );

      expect(result.text, '01090-100');
      expect(result.selection.extentOffset, 4);
    });

    test('CPF desloca a máscara ao inserir no meio do primeiro grupo', () {
      final formatter = CpfInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('111.111.111-11', 7),
        typing('111.1119.111-11', 8),
      );

      expect(result.text, '111.111.911-11');
      expect(result.selection.extentOffset, 9);
    });

    test('telefone insere dígito no meio sem trocar de máscara', () {
      final formatter = PhoneBrInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('(21) 98765-4321', 6),
        typing('(21) 938765-4321', 7),
      );

      expect(result.text, '(21) 93876-5432');
      expect(result.selection.extentOffset, 7);
    });

    test('CNPJ alfanumérico insere letra minúscula no meio e maiúscula', () {
      final formatter = CnpjInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('12.ABC.345/01DE-35', 6),
        typing('12.ABCz.345/01DE-35', 7),
      );

      expect(result.text, '12.ABC.Z34/501D-');
      expect(result.selection.extentOffset, 8);
    });
  });

  group('backspace', () {
    test('apaga o último dígito no fim do texto', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('01001-000', 9),
        typing('01001-00', 8),
      );

      expect(result.text, '01001-00');
      expect(result.selection.extentOffset, 8);
    });

    test('apaga o dígito anterior no meio do texto', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('01001-000', 5),
        typing('0100-000', 4),
      );

      expect(result.text, '01000-00');
      expect(result.selection.extentOffset, 4);
    });

    test('sobre o separador do CEP apaga o dígito anterior em um toque', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('01001-000', 6),
        typing('01001000', 5),
      );

      expect(result.text, '01000-00');
      expect(result.selection.extentOffset, 4);
    });

    test('sobre o ponto do CPF apaga o dígito anterior em um toque', () {
      final formatter = CpfInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('111.111.111-11', 4),
        typing('111111.111-11', 3),
      );

      expect(result.text, '111.111.111-1');
      expect(result.selection.extentOffset, 2);
    });

    test('sobre separador sem dígito anterior preserva o texto', () {
      final formatter = PhoneBrInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('(21) 98765-4321', 1),
        typing('21) 98765-4321', 0),
      );

      expect(result.text, '(21) 98765-4321');
      expect(result.selection.extentOffset, 0);
    });

    test(
      'no fim do telefone volta de 11 para 10 dígitos e troca a máscara',
      () {
        final formatter = PhoneBrInputFormatter();
        final result = formatter.formatEditUpdate(
          typing('(21) 98765-4321', 16),
          typing('(21) 98765-432', 15),
        );

        expect(result.text, '(21) 9876-5432');
        expect(result.selection.extentOffset, 14);
      },
    );
  });

  group('colagem', () {
    test('CEP colado com texto ao redor mantém só os oito dígitos', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('CEP: 01001-000 (Brasil)', 23),
      );

      expect(result.text, '01001-000');
      expect(result.selection.extentOffset, 9);
    });

    test('CPF sem pontuação colado sobre seleção é remascarado', () {
      final formatter = CpfInputFormatter();
      final result = formatter.formatEditUpdate(
        selecting('529.982.247-25', 0, 14),
        typing('52998224725', 11),
      );

      expect(result.text, '529.982.247-25');
      expect(result.selection.extentOffset, 14);
    });

    test('CPF colado com lixo e dígitos excedentes é truncado', () {
      final formatter = CpfInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('abc52998224725xyz99', 19),
      );

      expect(result.text, '529.982.247-25');
      expect(result.selection.extentOffset, 14);
    });

    test('CNPJ alfanumérico parcial em minúsculas ganha a máscara', () {
      final formatter = CnpjInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('12abc', 5),
      );

      expect(result.text, '12.ABC');
      expect(result.selection.extentOffset, 6);
    });

    test('colagem no meio do CEP reposiciona o cursor após o conteúdo', () {
      final formatter = CepInputFormatter();
      final result = formatter.formatEditUpdate(
        typing('01001-000', 5),
        typing('010099-000', 7),
      );

      expect(result.text, '01009-900');
      expect(result.selection.extentOffset, 7);
    });

    test('telefone colado com parênteses espúrios vira fixo', () {
      final formatter = PhoneBrInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('fixo: (21) 3333-4444 ok', 23),
      );

      expect(result.text, '(21) 3333-4444');
      expect(result.selection.extentOffset, 14);
    });
  });

  group('formatters de data e moeda', () {
    test('data aplica a máscara dd/MM/yyyy', () {
      final formatter = DateInputFormatter(format: 'dd/MM/yyyy');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('12032024', 8),
      );

      expect(result.text, '12/03/2024');
      expect(result.selection.extentOffset, 10);
    });

    test('data parcial mantém só o que couber no formato', () {
      final formatter = DateInputFormatter(format: 'dd/MM/yyyy');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('12', 2),
      );

      expect(result.text, '12');
      expect(result.selection.extentOffset, 2);
    });

    test('money formata com R\$ e vírgula decimal', () {
      final formatter = MoneyInputFormatter(size: 3, decimal: 2);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('12345', 5),
      );

      expect(result.text, 'R\$ 123,45');
      expect(result.selection.extentOffset, 8);
    });

    test('money sem decimal não insere vírgula', () {
      final formatter = MoneyInputFormatter(size: 5, decimal: 0);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('123', 3),
      );

      expect(result.text, 'R\$ 123');
      expect(result.selection.extentOffset, 6);
    });

    test('money trunca além de size mais decimal', () {
      final formatter = MoneyInputFormatter(size: 3, decimal: 2);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('123456', 6),
      );

      expect(result.text, 'R\$ 123,45');
      expect(result.selection.extentOffset, 8);
    });

    test('money com decimal e texto menor que size não insere vírgula', () {
      final formatter = MoneyInputFormatter(size: 5, decimal: 2);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('123', 3),
      );

      expect(result.text, 'R\$ 123');
      expect(result.selection.extentOffset, 6);
    });

    test('number formata centavos como moeda pt-BR', () {
      final formatter = NumberInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('123456', 6),
      );

      expect(result.text, '1.234,56');
      expect(result.selection.extentOffset, 8);
    });

    test('number limpa o texto quando não há dígitos', () {
      final formatter = NumberInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('abc', 3),
      );

      expect(result.text, '');
      expect(result.selection.extentOffset, 0);
    });

    test(
      'number digita da direita para a esquerda estilo caixa eletrônico',
      () {
        final formatter = NumberInputFormatter();

        // Digita '1' em campo vazio -> '0,01'
        var result = formatter.formatEditUpdate(
          const TextEditingValue(),
          typing('1', 1),
        );
        expect(result.text, '0,01');
        expect(result.selection.extentOffset, 4);

        // Digita '2' ao final -> '0,12'
        result = formatter.formatEditUpdate(result, typing('0,012', 5));
        expect(result.text, '0,12');
        expect(result.selection.extentOffset, 4);

        // Digita '3' -> '1,23'
        result = formatter.formatEditUpdate(result, typing('0,123', 5));
        expect(result.text, '1,23');
        expect(result.selection.extentOffset, 4);

        // Digita '4' -> '12,34'
        result = formatter.formatEditUpdate(result, typing('1,234', 5));
        expect(result.text, '12,34');
        expect(result.selection.extentOffset, 5);

        // Digita '5' -> '123,45'
        result = formatter.formatEditUpdate(result, typing('12,345', 6));
        expect(result.text, '123,45');
        expect(result.selection.extentOffset, 6);

        // Digita '6' -> '1.234,56'
        result = formatter.formatEditUpdate(result, typing('123,456', 7));
        expect(result.text, '1.234,56');
        expect(result.selection.extentOffset, 8);
      },
    );

    test(
      'number backspace apaga da direita para a esquerda e limpa ao zerar',
      () {
        final formatter = NumberInputFormatter();

        // Estado inicial: '0,05'
        final valorInicial = TextEditingValue(
          text: '0,05',
          selection: const TextSelection.collapsed(offset: 4),
        );

        // Backspace remove '5', restando '0,0' (zeros)
        final apagando = formatter.formatEditUpdate(
          valorInicial,
          const TextEditingValue(
            text: '0,0',
            selection: TextSelection.collapsed(offset: 3),
          ),
        );

        // Ao zerar via backspace, limpa o campo
        expect(apagando.text, '');
        expect(apagando.selection.extentOffset, 0);
      },
    );

    test('number ignora caracteres não-dígitos mantendo o valor corrente', () {
      final formatter = NumberInputFormatter();
      final valorCorrente = TextEditingValue(
        text: '12,34',
        selection: const TextSelection.collapsed(offset: 5),
      );

      final result = formatter.formatEditUpdate(
        valorCorrente,
        const TextEditingValue(
          text: '12,34x',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );

      expect(result.text, '12,34');
      expect(result.selection.extentOffset, 5);
    });

    test('currency aplica símbolo e separadores', () {
      final formatter = CurrencyInputFormatter(symbol: 'R\$ ');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('1234', 4),
      );

      expect(result.text, 'R\$ 12,34');
      expect(result.selection.extentOffset, 8);
    });

    test('currency sem decimal formata como inteiro', () {
      final formatter = CurrencyInputFormatter(decimalDigits: 0);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typing('1234', 4),
      );

      expect(result.text, '1.234');
      expect(result.selection.extentOffset, 5);
    });

    test('currency com caret no início limpa o texto', () {
      final formatter = CurrencyInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(
          text: '1234',
          selection: TextSelection.collapsed(offset: 0),
        ),
      );

      expect(result.text, '');
      expect(result.selection.extentOffset, 0);
    });
  });
}

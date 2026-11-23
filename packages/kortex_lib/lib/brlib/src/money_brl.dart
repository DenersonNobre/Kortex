import 'package:kortex_lib/core/models/money.dart';

/// Extensões de conveniência e ergonomia brasileira (BRL) para [Money].
///
/// O Real brasileiro opera na moeda ISO `BRL` com escala 2 (centavos),
/// separador decimal `,` e separador de agrupamento de milhar `.`.
extension MoneyBrlX on Money {
  /// Código canônico da moeda brasileira.
  static const currencyCodeBrl = 'BRL';

  /// Escala canônica (2 casas decimais / centavos).
  static const scaleBrl = 2;

  /// Cria [Money] em Reais a partir da quantidade inteira de [centavos].
  static Money fromCents(int centavos) => Money.fromMinorUnits(
    centavos,
    currencyCode: currencyCodeBrl,
    scale: scaleBrl,
  );

  /// Cria [Money] em Reais a partir de um valor em ponto flutuante [valorReal].
  ///
  /// Converte para centavos arredondando (`round()`). Valores negativos saturam em 0.
  static Money fromReal(double valorReal) {
    final centavos = (valorReal * 100).round();
    return fromCents(centavos < 0 ? 0 : centavos);
  }

  /// Retorna uma instância de [Money] com valor zero em BRL.
  static Money zero() => fromCents(0);

  /// Tenta converter uma string pt-BR (ex.: `"1.250,50"`) em [Money].
  static MoneyParseResult tryParseBrl(String? source) => Money.tryParse(
    source,
    currencyCode: currencyCodeBrl,
    scale: scaleBrl,
    decimalSeparator: ',',
    groupSeparator: '.',
  );

  /// Tenta converter a string pt-BR e retorna a instância de [Money] ou `null` se inválida.
  static Money? tryParseBrlOrNull(String? source) {
    final result = tryParseBrl(source);
    return result.isSuccess ? result.value : null;
  }

  /// Valor inteiro em centavos (`minorUnits.toInt()`).
  int get cents => minorUnits.toInt();

  /// Valor em ponto flutuante (`minorUnits.toDouble() / 100.0`).
  double get toDouble => minorUnits.toDouble() / 100.0;

  /// Formata o valor sem símbolo (ex.: `"1.250,50"`).
  String get formatted => format(decimalSeparator: ',', groupSeparator: '.');

  /// Formata o valor com prefixo de Real (ex.: `"R$ 1.250,50"`).
  String get formattedBrl => 'R\$ $formatted';

  /// `true` se o valor monetário for exatamente zero.
  bool get isZero => minorUnits == BigInt.zero;
}

/// Erros de parsing de um valor monetário.
enum MoneyParseError { empty, invalidFormat }

/// Resultado explícito da leitura textual de [Money].
class MoneyParseResult {
  const MoneyParseResult._({this.value, this.failure});

  factory MoneyParseResult.success(Money value) =>
      MoneyParseResult._(value: value);

  factory MoneyParseResult.failed(MoneyParseError failure) =>
      MoneyParseResult._(failure: failure);

  final Money? value;
  final MoneyParseError? failure;

  bool get isSuccess => value != null;
  bool get isFailure => failure != null;
}

/// Erro ao combinar ou comparar valores com moedas/escalas incompatíveis.
class MoneyCurrencyMismatch implements Exception {
  const MoneyCurrencyMismatch(this.left, this.right);

  final Money left;
  final Money right;

  @override
  String toString() =>
      'Moedas ou escalas incompatíveis: '
      '${left.currencyCode}/${left.scale} e '
      '${right.currencyCode}/${right.scale}.';
}

/// Valor monetário imutável, armazenado como inteiro em unidade mínima.
///
/// A moeda e a escala são obrigatórias. Esta classe não escolhe símbolos,
/// locale, arredondamento de negócio ou regra para impedir saldo negativo.
class Money implements Comparable<Money> {
  Money._({
    required this.minorUnits,
    required this.currencyCode,
    required this.scale,
  });

  factory Money.fromMinorUnits(
    int amount, {
    required String currencyCode,
    required int scale,
  }) => Money.fromBigInt(
    BigInt.from(amount),
    currencyCode: currencyCode,
    scale: scale,
  );

  factory Money.fromBigInt(
    BigInt amount, {
    required String currencyCode,
    required int scale,
  }) {
    _validateConfiguration(currencyCode, scale);
    return Money._(
      minorUnits: amount,
      currencyCode: currencyCode.toUpperCase(),
      scale: scale,
    );
  }

  final BigInt minorUnits;
  final String currencyCode;
  final int scale;

  /// Lê um valor usando separadores fornecidos pelo consumidor.
  ///
  /// Casas além de [scale] são arredondadas pelo texto, half away from zero.
  /// Uma configuração inválida lança [ArgumentError]; texto inválido retorna
  /// um [MoneyParseResult] de falha.
  static MoneyParseResult tryParse(
    String? source, {
    required String currencyCode,
    required int scale,
    required String decimalSeparator,
    String? groupSeparator,
  }) {
    _validateConfiguration(currencyCode, scale);
    _validateSeparators(decimalSeparator, groupSeparator);

    final text = source?.trim() ?? '';
    if (text.isEmpty) {
      return MoneyParseResult.failed(MoneyParseError.empty);
    }

    final isNegative = text.startsWith('-');
    final unsigned = text.startsWith('-') || text.startsWith('+')
        ? text.substring(1)
        : text;
    final decimalParts = unsigned.split(decimalSeparator);
    if (decimalParts.length > 2) {
      return MoneyParseResult.failed(MoneyParseError.invalidFormat);
    }

    final integerPart = decimalParts.first;
    final fractionPart = decimalParts.length == 2 ? decimalParts[1] : '';
    final integerDigits = _parseInteger(integerPart, groupSeparator);
    if (integerDigits == null || !_isDigits(fractionPart, allowEmpty: true)) {
      return MoneyParseResult.failed(MoneyParseError.invalidFormat);
    }

    final retainedFraction = fractionPart.padRight(scale, '0');
    final scaledFraction = scale == 0
        ? ''
        : retainedFraction.substring(0, scale);
    var amount = BigInt.parse('$integerDigits$scaledFraction');

    if (fractionPart.length > scale && int.parse(fractionPart[scale]) >= 5) {
      amount += BigInt.one;
    }
    if (isNegative) {
      amount = -amount;
    }

    return MoneyParseResult.success(
      Money.fromBigInt(amount, currencyCode: currencyCode, scale: scale),
    );
  }

  Money add(Money other) {
    _ensureCompatible(other);
    return _copy(minorUnits + other.minorUnits);
  }

  Money subtract(Money other) {
    _ensureCompatible(other);
    return _copy(minorUnits - other.minorUnits);
  }

  Money multiply(int quantity) => _copy(minorUnits * BigInt.from(quantity));

  Money negate() => _copy(-minorUnits);

  /// Formata com separadores explícitos, sem símbolo de moeda.
  String format({required String decimalSeparator, String? groupSeparator}) {
    _validateSeparators(decimalSeparator, groupSeparator);
    final negative = minorUnits.isNegative;
    final absolute = minorUnits.abs().toString().padLeft(scale + 1, '0');
    final integerPart = scale == 0
        ? absolute
        : absolute.substring(0, absolute.length - scale);
    final fractionPart = scale == 0
        ? ''
        : absolute.substring(absolute.length - scale);
    final grouped = _groupDigits(integerPart, groupSeparator);
    final sign = negative ? '-' : '';

    if (scale == 0) {
      return '$sign$grouped';
    }
    return '$sign$grouped$decimalSeparator$fractionPart';
  }

  @override
  int compareTo(Money other) {
    _ensureCompatible(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Money &&
          other.minorUnits == minorUnits &&
          other.currencyCode == currencyCode &&
          other.scale == scale);

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode, scale);

  @override
  String toString() => '$currencyCode:$minorUnits/$scale';

  Money _copy(BigInt amount) =>
      Money._(minorUnits: amount, currencyCode: currencyCode, scale: scale);

  void _ensureCompatible(Money other) {
    if (currencyCode != other.currencyCode || scale != other.scale) {
      throw MoneyCurrencyMismatch(this, other);
    }
  }
}

String? _parseInteger(String value, String? groupSeparator) {
  if (groupSeparator == null || !value.contains(groupSeparator)) {
    return _isDigits(value) ? value : null;
  }

  final groups = value.split(groupSeparator);
  if (groups.isEmpty ||
      groups.first.isEmpty ||
      groups.first.length > 3 ||
      !_isDigits(groups.first) ||
      groups.skip(1).any((group) => group.length != 3 || !_isDigits(group))) {
    return null;
  }
  return groups.join();
}

bool _isDigits(String value, {bool allowEmpty = false}) =>
    (allowEmpty && value.isEmpty) || RegExp(r'^[0-9]+$').hasMatch(value);

void _validateConfiguration(String currencyCode, int scale) {
  if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(currencyCode)) {
    throw ArgumentError.value(currencyCode, 'currencyCode');
  }
  if (scale < 0) {
    throw ArgumentError.value(scale, 'scale');
  }
}

void _validateSeparators(String decimalSeparator, String? groupSeparator) {
  if (decimalSeparator.length != 1 ||
      RegExp(r'[0-9\s]').hasMatch(decimalSeparator)) {
    throw ArgumentError.value(decimalSeparator, 'decimalSeparator');
  }
  if (groupSeparator != null &&
      (groupSeparator.length != 1 ||
          groupSeparator == decimalSeparator ||
          RegExp(r'[0-9\s]').hasMatch(groupSeparator))) {
    throw ArgumentError.value(groupSeparator, 'groupSeparator');
  }
}

String _groupDigits(String value, String? separator) {
  if (separator == null || value.length <= 3) {
    return value;
  }
  final firstLength = value.length % 3 == 0 ? 3 : value.length % 3;
  final parts = <String>[value.substring(0, firstLength)];
  for (var index = firstLength; index < value.length; index += 3) {
    parts.add(value.substring(index, index + 3));
  }
  return parts.join(separator);
}

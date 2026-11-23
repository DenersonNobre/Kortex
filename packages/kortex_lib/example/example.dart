// ignore_for_file: avoid_print

import 'package:kortex_lib/kortex_lib.dart';

void main() {
  // brlib: Brazilian document validation and formatting
  final cpf = Cpf.tryParse('52998224725');
  print('CPF valid: ${cpf.isSuccess}');
  print('CPF formatted: ${cpf.value?.formatted}');

  // core: Result pattern
  final parsed = parsePositive('42');
  print(parsed.fold(
    onSuccess: (value) => 'Value: $value',
    onFailure: (failure) => 'Error: ${failure.message}',
  ));

  // core: Money
  final total = Money.fromMinorUnits(2590, currencyCode: 'BRL', scale: 2);
  print('Total: ${total.format(decimalSeparator: ',', groupSeparator: '.')}');
}

IResult<int, IFailure> parsePositive(String raw) {
  final value = int.tryParse(raw);
  if (value == null || value <= 0) {
    return const ValidationFailure('Value must be a positive integer')
        .toFailure<int>();
  }
  return value.toSuccess<IFailure>();
}

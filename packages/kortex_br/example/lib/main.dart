import 'package:kortex_br/kortex_br.dart';

void main() {
  const rawCpf = '52998224725';
  print('CPF valido: ${CpfValidator.isValid(rawCpf)}');
  print('CPF formatado: ${CpfFormatter.format(rawCpf)}');
  print('BRL: ${BrlCurrencyFormatter.formatCents(123456)}');
}

import 'package:kortex_br/kortex_br.dart';

void main() {
  const rawCpf = '52998224725';
  const rawCnpj = '11222333000181';
  const rawCep = '01001000';
  const rawPhone = '11988887777';

  assert(CpfValidator.isValid(rawCpf));
  assert(CnpjValidator.isValid(rawCnpj));
  assert(CepValidator.isValid(rawCep));
  assert(PhoneBrValidator.isValid(rawPhone));
  assert(PixKeyValidator.isValid('dev@bonusoft.com.br'));
  assert(MercosulPlateValidator.isValid('ABC1D23'));

  final formatted = [
    CpfFormatter.format(rawCpf),
    CnpjFormatter.format(rawCnpj),
    CepFormatter.format(rawCep),
    PhoneBrFormatter.format(rawPhone),
    BrlCurrencyFormatter.formatCents(123456),
  ];
  assert(formatted.length == 5);
}

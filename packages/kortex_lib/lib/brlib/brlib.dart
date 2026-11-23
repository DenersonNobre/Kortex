library;

/// Convenções brasileiras: validadores, formatação e `TextInputFormatter`s.
///
/// Os algoritmos são Dart puro; os formatters de input são a borda Flutter
/// deste módulo, como `widgets` é para o `core`.

export 'src/cpf.dart';
export 'src/document.dart';
export 'src/endereco.dart';
export 'src/formatters/cep_formatter.dart';
export 'src/formatters/cnpj_formatter.dart';
export 'src/formatters/cpf_formatter.dart';
export 'src/formatters/phone_br_formatter.dart';
export 'src/input_formatters/cep_input_formatter.dart';
export 'src/input_formatters/cnpj_input_formatter.dart';
export 'src/input_formatters/cpf_input_formatter.dart';
export 'src/input_formatters/currency_input_formatter.dart';
export 'src/input_formatters/date_input_formatter.dart';
export 'src/input_formatters/digit_mask_input_formatter.dart';
export 'src/input_formatters/integer_input_formatter.dart';
export 'src/input_formatters/money_input_formatter.dart';
export 'src/input_formatters/number_input_formatter.dart';
export 'src/input_formatters/phone_br_input_formatter.dart';
export 'src/money_brl.dart';
export 'src/validators/cep_validator.dart';
export 'src/validators/cnpj_validator.dart';
export 'src/validators/cpf_validator.dart';
export 'src/validators/phone_br_validator.dart';
export 'src/validators/uf_validator.dart';

import 'formatters/cpf_formatter.dart';
import 'validators/cpf_validator.dart';

/// Resultado explícito de parsing para [Cpf].
class CpfParseResult {
  const CpfParseResult._({this.value, required this.isSuccess});

  const CpfParseResult.success(Cpf cpf) : this._(value: cpf, isSuccess: true);

  const CpfParseResult.failed() : this._(value: null, isSuccess: false);

  final Cpf? value;
  final bool isSuccess;

  bool get isFailure => !isSuccess;

  Cpf? getOrNull() => value;
}

/// Abstração de custo zero (Zero-Cost Abstraction) para Cadastro de Pessoas Físicas (CPF).
///
/// Encapsula a string pura de 11 dígitos sem custo de alocação no Heap.
/// Normaliza a entrada eliminando máscaras e pontuações.
extension type const Cpf(String value) {
  /// Construtor de normalização: limpa qualquer caractere não numérico.
  factory Cpf.parse(String raw) =>
      Cpf(raw.trim().replaceAll(RegExp(r'\D'), ''));

  /// Tenta fazer o parse e valida se o CPF possui 11 dígitos e dígitos verificadores válidos.
  static CpfParseResult tryParse(String? input) {
    if (input == null) {
      return const CpfParseResult.failed();
    }
    final digits = input.trim().replaceAll(RegExp(r'\D'), '');
    if (CpfValidator.isValid(digits)) {
      return CpfParseResult.success(Cpf(digits));
    }
    return const CpfParseResult.failed();
  }

  /// Retorna o CPF formatado com máscara padrão (`000.000.000-00`).
  String get masked => formatCpf(value);

  /// Alias de conveniência para formatação com máscara.
  String get formatted => masked;

  /// Verifica se os 11 dígitos possuem dígitos verificadores matematicamente válidos.
  bool get isValid => CpfValidator.isValid(value);

  /// `true` se estiver vazio.
  bool get isEmpty => value.isEmpty;

  /// `true` se não estiver vazio.
  bool get isNotEmpty => value.isNotEmpty;
}

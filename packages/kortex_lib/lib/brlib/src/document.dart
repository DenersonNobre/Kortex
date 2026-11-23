import 'formatters/cnpj_formatter.dart';
import 'formatters/cpf_formatter.dart';
import 'validators/cnpj_validator.dart';
import 'validators/cpf_validator.dart';

/// Abstração de custo zero (Zero-Cost Abstraction) para documento brasileiro.
///
/// Encapsula CPF (11 dígitos) e CNPJ (14 dígitos, numérico ou alfanumérico)
/// sem criar instâncias no Heap em tempo de execução (Object Calisthenics R3
/// sem pressão no Garbage Collector). O valor canônico é normalizado
/// (maiúsculas, sem máscara); a validação delega aos validadores da `brlib`.
extension type const Document(String value) {
  /// Normaliza qualquer entrada: maiúsculas, sem máscara ou separadores.
  factory Document.parse(String raw) =>
      Document(raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''));

  /// Indica ausência de documento informado.
  bool get isEmpty => value.isEmpty;

  /// Indica tamanho compatível com CPF (11 posições).
  bool get isCpf => value.length == 11;

  /// Indica tamanho compatível com CNPJ (14 posições).
  bool get isCnpj => value.length == 14;

  /// Verifica os dígitos verificadores via validadores canônicos.
  bool get isValid =>
      CpfValidator.isValid(value) || CnpjValidator.isValid(value);

  /// Retorna o documento formatado (CPF `000.000.000-00` ou CNPJ
  /// `00.000.000/0000-00`); devolve o valor puro quando inválido.
  String get formatted {
    if (CpfValidator.isValid(value)) return formatCpf(value);
    if (CnpjValidator.isValid(value)) return formatCnpj(value);
    return value;
  }
}

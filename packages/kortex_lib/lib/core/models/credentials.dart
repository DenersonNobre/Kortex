import 'package:kortex_forms/kortex_forms.dart';

final _emailValidator = kortexValidator<String>().email().build();

/// Value Object de E-mail com validação estrutural e normalização em minúsculas.
///
/// Lança [FormatException] se a entrada não for um formato de e-mail válido.
class Email {
  final String valor;

  Email(String entrada) : valor = _validate(entrada.trim().toLowerCase());

  static String _validate(String entrada) {
    if (_emailValidator(entrada) != null) {
      throw FormatException('Email inválido: $entrada');
    }
    return entrada;
  }

  /// Retorna `true` se [entrada] atender ao formato de e-mail válido.
  static bool valido(String entrada) =>
      _emailValidator(entrada.trim().toLowerCase()) == null;

  /// Tenta criar [Email] e retorna `null` se inválido.
  static Email? tryParse(String? entrada) {
    if (entrada == null) return null;
    try {
      return Email(entrada);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => valor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Email && other.valor == valor);

  @override
  int get hashCode => valor.hashCode;
}

/// Value Object de Senha com mascaramento em `toString` para prevenção de vazamento em logs.
///
/// Exige o tamanho mínimo configurado (padrão: 6 caracteres).
class Senha {
  final String valor;

  Senha(String entrada, {int tamanhoMinimo = tamanhoMinimoPadrao})
    : valor = _validate(entrada, tamanhoMinimo);

  static const int tamanhoMinimoPadrao = 6;

  static String _validate(String entrada, int min) {
    if (entrada.length < min) {
      throw FormatException('Senha deve ter no mínimo $min caracteres');
    }
    return entrada;
  }

  /// Retorna `true` se a senha possuir o tamanho mínimo necessário.
  static bool valido(
    String entrada, {
    int tamanhoMinimo = tamanhoMinimoPadrao,
  }) => entrada.length >= tamanhoMinimo;

  /// Tenta criar [Senha] e retorna `null` se inválida.
  static Senha? tryParse(
    String? entrada, {
    int tamanhoMinimo = tamanhoMinimoPadrao,
  }) {
    if (entrada == null) return null;
    try {
      return Senha(entrada, tamanhoMinimo: tamanhoMinimo);
    } catch (_) {
      return null;
    }
  }

  /// Nunca exibe a senha em texto claro.
  @override
  String toString() => 'senha: ****';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Senha && other.valor == valor);

  @override
  int get hashCode => valor.hashCode;
}

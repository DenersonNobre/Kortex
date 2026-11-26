import 'cnpj.dart';
import 'cpf.dart';
import 'digits.dart';

/// Brazilian PIX key validator (CPF, CNPJ, email, phone, or EVP UUID).
abstract final class PixKeyValidator {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _evpRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _e164BrPhone = RegExp(r'^\+55\d{10,11}$');

  /// Returns `null` when [value] is a valid PIX key, or an error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Chave PIX obrigatoria';
    final trimmed = value.trim();
    if (_evpRegex.hasMatch(trimmed)) return null;
    if (_emailRegex.hasMatch(trimmed)) return null;
    if (_e164BrPhone.hasMatch(trimmed)) return null;
    final digits = digitsOnly(trimmed);
    if (digits.length == 11 && CpfValidator.isValid(digits)) return null;
    if (digits.length == 14 && CnpjValidator.isValid(digits)) return null;
    return 'Chave PIX invalida';
  }

  /// Returns `true` when [value] is a valid PIX key.
  static bool isValid(String? value) => validate(value) == null;
}

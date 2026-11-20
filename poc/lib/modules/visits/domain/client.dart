/// Cliente (site) da visita tecnica (`Client`).
///
/// SRP: identificar o site atendido com nome e telefone validos.
/// NAO faz: agenda, persistencia ou UI.
///
/// Patterns: Entidade imutavel + fabrica que devolve `Result`.
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'visit_failures.dart';

/// Telefone do cliente: apenas digitos, de 10 a 11.
final RegExp _phonePattern = RegExp(r'^\d{10,11}$');

/// Cliente sempre valido (construcao so via `create`).
final class Client {
  const Client._({
    required this.id,
    required this.name,
    required this.phone,
    this.address = '',
  });

  /// Identificador (`0` antes da primeira persistencia).
  final int id;

  /// Nome do cliente.
  final String name;

  /// Telefone somente com digitos.
  final String phone;

  /// Endereco do site (opcional).
  final String address;

  /// Devolve copia com o [id] aplicado (persistência).
  Client withId(int id) =>
      Client._(id: id, name: name, phone: phone, address: address);

  /// Valida os campos e devolve `Ok` ou `Fail` com codigo estavel.
  static Result<Client> create({
    required String name,
    required String phone,
    String address = '',
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Fail(
        VisitFailureCodes.clientPhoneInvalid,
        'Cliente sem nome.',
      );
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (!_phonePattern.hasMatch(digits)) {
      return const Fail(
        VisitFailureCodes.clientPhoneInvalid,
        'Telefone do cliente invalido.',
      );
    }
    return Ok(
      Client._(
        id: 0,
        name: trimmedName,
        phone: digits,
        address: address.trim(),
      ),
    );
  }
}

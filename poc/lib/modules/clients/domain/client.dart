/// Cliente (site) atendido (`Client`).
///
/// SRP: identificar o site com nome e telefone validos.
/// NAO faz: agenda, persistencia ou UI.
///
/// Patterns: Entidade imutavel + fabrica que devolve `IResult` + `_copy`.
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'client_failures.dart';

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

  /// Valida os campos e devolve `Ok` ou `Fail` com codigo estavel.
  static AppResult<Client> create({
    required String name,
    required String phone,
    String address = '',
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Failure(
        AppFailure(ClientFailureCodes.nameEmpty, 'Cliente sem nome.'),
      );
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (!_phonePattern.hasMatch(digits)) {
      return const Failure(
        AppFailure(
          ClientFailureCodes.phoneInvalid,
          'Telefone do cliente invalido.',
        ),
      );
    }
    return Success(
      Client._(
        id: 0,
        name: trimmedName,
        phone: digits,
        address: address.trim(),
      ),
    );
  }

  /// Devolve copia com os campos sobrescritos (unico ponto de reconstrucao).
  Client copyWith({int? id, String? name, String? phone, String? address}) =>
      Client._(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
      );

  /// Devolve copia com o [id] aplicado (persistencia).
  Client withId(int id) => copyWith(id: id);
}

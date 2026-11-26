import 'dart:convert';

/// Contrato para DTOs e entidades serializáveis em Mapa/JSON.
abstract class IMappable {
  Map<String, dynamic> toMap();

  String toJson() => json.encode(toMap());
}

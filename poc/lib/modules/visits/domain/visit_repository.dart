/// Ports de persistencia do modulo de visitas.
///
/// SRP: contratos minimos de leitura e escrita por agregado. NAO faz:
/// validar regras nem escolher tecnologia de armazenamento.
///
/// Patterns: Port explicita (ISP: so o que as features usam).
/// Dependencias: entidades do dominio (puro, sem Flutter).
library;

import 'client.dart';
import 'technician.dart';
import 'visit.dart';

/// Contrato de leitura e escrita das visitas.
abstract interface class VisitRepository {
  /// Lista todas as visitas (ordenadas por `id`).
  Future<List<Visit>> listVisits();

  /// Busca por [id] ou `null` quando ausente.
  Future<Visit?> findVisitById(int id);

  /// Insere (gera `id` quando `0`) ou substitui pelo `id`.
  Future<Visit> saveVisit(Visit visit);

  /// Remove por [id]; ausente e' no-op.
  Future<void> deleteVisit(int id);
}

/// Contrato de leitura e escrita dos clientes.
abstract interface class ClientRepository {
  /// Lista todos os clientes (ordenados por `id`).
  Future<List<Client>> listClients();

  /// Busca por [id] ou `null` quando ausente.
  Future<Client?> findClientById(int id);

  /// Insere (gera `id` quando `0`) ou substitui pelo `id`.
  Future<Client> saveClient(Client client);
}

/// Contrato de leitura e escrita dos tecnicos.
abstract interface class TechnicianRepository {
  /// Lista todos os tecnicos (ordenados por `id`).
  Future<List<Technician>> listTechnicians();

  /// Busca por [id] ou `null` quando ausente.
  Future<Technician?> findTechnicianById(int id);

  /// Insere (gera `id` quando `0`) ou substitui pelo `id`.
  Future<Technician> saveTechnician(Technician technician);
}

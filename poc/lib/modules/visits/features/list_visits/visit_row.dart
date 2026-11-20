/// Leitura de visitas com join de cliente e tecnico (`VisitRow`).
///
/// SRP: transportar para a UI a visita enriched com nomes resolvidos.
/// NAO faz: validar, persistir nem observar.
///
/// Patterns: DTO imutavel montado pela query.
/// Dependencias: apenas `dart:core`.
library;

/// Linha da lista de visitas com cliente, tecnico e progresso.
final class VisitRow {
  /// Cria a linha com os campos resolvidos pela query.
  const VisitRow({
    required this.id,
    required this.title,
    required this.status,
    required this.clientName,
    required this.technicianName,
    required this.progress,
    required this.scheduledAt,
  });

  /// Identificador da visita.
  final int id;

  /// Titulo da visita.
  final String title;

  /// Situacao atual.
  final String status;

  /// Nome do cliente (site).
  final String clientName;

  /// Nome do tecnico responsavel.
  final String technicianName;

  /// Fracao do checklist concluida.
  final double progress;

  /// Data e hora agendadas.
  final DateTime scheduledAt;
}

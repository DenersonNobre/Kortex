import 'paginate.dart';

/// Predicado de leitura genérico (kernel).
///
/// `fields` é um mapa campo → valor; cada adapter (sqlite, rest) traduz para
/// o mecanismo nativo (WHERE, query params).
class Filter {
  final Map<String, dynamic> fields;

  const Filter(this.fields);
}

/// Consulta de leitura canônica (kernel).
///
/// Compõe predicado e paginação como irmãos opcionais — quem só pagina não
/// instancia `Filter`, quem só filtra não instancia `Paginate`.
class Query {
  final Filter? filter;
  final Paginate? paginate;

  const Query({this.filter, this.paginate});
}

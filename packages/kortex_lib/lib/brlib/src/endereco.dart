// Endereco — Value Object para endereços brasileiros.
// Encapsula logradouro, número, complemento, bairro, cidade, estado e CEP.
// Imutável; `isVazio` distingue "não informado" de "informado parcialmente".
// Inclui serialização para mapa compatível com colunas UPPER/padrão de banco de dados.

class Endereco {
  const Endereco({
    this.cep,
    this.bairro,
    this.cidade,
    this.estado,
    this.logradouro,
    this.numero,
    this.complemento,
  });

  final String? cep;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? logradouro;
  final String? numero;
  final String? complemento;

  /// Lê de mapa com chaves UPPER (CEP..COMPLEMENTO) ou padrão de banco de dados.
  /// Chaves ausentes ou em branco viram `null` — nunca string vazia.
  factory Endereco.fromColumns(Map<String, dynamic> colunas) => Endereco(
    cep: _texto(colunas['CEP'] ?? colunas['cep']),
    bairro: _texto(colunas['BAIRRO'] ?? colunas['bairro']),
    cidade: _texto(colunas['CIDADE'] ?? colunas['cidade']),
    estado: _texto(
      colunas['ESTADO'] ?? colunas['estado'] ?? colunas['UF'] ?? colunas['uf'],
    ),
    logradouro: _texto(
      colunas['ENDERECO'] ??
          colunas['LOGRADOURO'] ??
          colunas['endereco'] ??
          colunas['logradouro'],
    ),
    numero: _texto(colunas['NUMERO'] ?? colunas['numero']),
    complemento: _texto(colunas['COMPLEMENTO'] ?? colunas['complemento']),
  );

  /// Projeta para as sete colunas UPPER; `ENDERECO` carrega o logradouro.
  Map<String, dynamic> toColumns() => {
    'CEP': cep,
    'BAIRRO': bairro,
    'CIDADE': cidade,
    'ESTADO': estado,
    'ENDERECO': logradouro,
    'NUMERO': numero,
    'COMPLEMENTO': complemento,
  };

  /// Projeta para formato map amigável / json (camelCase).
  Map<String, dynamic> toMap() => {
    'cep': cep,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'logradouro': logradouro,
    'numero': numero,
    'complemento': complemento,
  };

  /// True quando nenhuma das sete propriedades foi informada.
  bool get isVazio =>
      cep == null &&
      bairro == null &&
      cidade == null &&
      estado == null &&
      logradouro == null &&
      numero == null &&
      complemento == null;

  /// Substitui apenas os campos informados; `null` preserva o valor atual.
  Endereco copyWith({
    String? cep,
    String? bairro,
    String? cidade,
    String? estado,
    String? logradouro,
    String? numero,
    String? complemento,
  }) => Endereco(
    cep: cep ?? this.cep,
    bairro: bairro ?? this.bairro,
    cidade: cidade ?? this.cidade,
    estado: estado ?? this.estado,
    logradouro: logradouro ?? this.logradouro,
    numero: numero ?? this.numero,
    complemento: complemento ?? this.complemento,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Endereco &&
          runtimeType == other.runtimeType &&
          cep == other.cep &&
          bairro == other.bairro &&
          cidade == other.cidade &&
          estado == other.estado &&
          logradouro == other.logradouro &&
          numero == other.numero &&
          complemento == other.complemento;

  @override
  int get hashCode =>
      Object.hash(cep, bairro, cidade, estado, logradouro, numero, complemento);

  @override
  String toString() {
    if (isVazio) return 'Endereco.vazio';
    final partes = <String>[];
    if (logradouro != null) {
      partes.add(numero != null ? '$logradouro, $numero' : logradouro!);
    }
    if (complemento != null) partes.add(complemento!);
    if (bairro != null) partes.add(bairro!);
    if (cidade != null || estado != null) {
      partes.add('${cidade ?? ""}${estado != null ? "/$estado" : ""}');
    }
    if (cep != null) partes.add('CEP $cep');
    return partes.join(' - ');
  }
}

String? _texto(Object? bruto) {
  if (bruto is! String) {
    return null;
  }
  final aparado = bruto.trim();
  return aparado.isEmpty ? null : aparado;
}

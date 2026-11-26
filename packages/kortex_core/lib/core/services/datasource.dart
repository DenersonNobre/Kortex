// Contratos de dados por operação (ISP — fronteira DIP): cada porta expõe
// apenas a operação que negocia, sem coação de CRUD completo. Quem precisa do
// conjunto combina as portas no agregado [ICrudDataSource].
//
// Todas as operações devolvem [IResult] para que falhas de I/O fluam pelo
// mesmo monad do domínio, sem try/catch obrigatório na camada consumidora.

import '../helpers/key_value.dart';
import '../helpers/query.dart';
import '../patterns/result.dart';

/// Raiz da fronteira: identifica o recurso persistido (nome da tabela/entidade).
abstract class IDataSource {
  final String resource;

  IDataSource({required this.resource});
}

/// Porta de inserção de um registro em `Map<String, dynamic>`.
/// Sucesso carrega o identificador/resultado da inserção (rowid, body…).
abstract class ICreateDataSource {
  Future<IResult<Object?, IFailure>> create(Map<String, dynamic> map);
}

/// Porta de leitura da coletânea (query opcional delegada ao adapter).
abstract class IReadAllDataSource {
  Future<IResult<List<Map<String, dynamic>>, IFailure>> readAll(Query? query);
}

/// Porta de leitura pontual por chave; `Success(null)` = não encontrado
/// (ausência de registro não é erro).
abstract class IReadByIdDataSource {
  Future<IResult<Map<String, dynamic>?, IFailure>> readById(KeyValue keyValue);
}

/// Porta de atualização: identifica o registro por [KeyValue] e aplica `map`.
/// Sucesso carrega o número de linhas afetadas ou o body de resposta.
abstract class IUpdateDataSource {
  Future<IResult<Object?, IFailure>> update(
    KeyValue keyValue,
    Map<String, dynamic> map,
  );
}

/// Porta de exclusão por [KeyValue].
/// Sucesso carrega o número de linhas afetadas ou o body de resposta.
abstract class IDeleteDataSource {
  Future<IResult<Object?, IFailure>> delete(KeyValue keyValue);
}

/// Agregado CRUD: quem implementa satisfaz as cinco portas de uma vez.
abstract class ICrudDataSource extends IDataSource
    implements
        ICreateDataSource,
        IReadAllDataSource,
        IReadByIdDataSource,
        IUpdateDataSource,
        IDeleteDataSource {
  ICrudDataSource({required super.resource});
}

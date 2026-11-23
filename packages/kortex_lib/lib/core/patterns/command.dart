// [GoF Command] (behavioral) puro: encapsula uma ação assíncrona e publica seu
// estado através de [Observable], agnóstico de framework.
//
// SRP: executa a ação, guarda o estado de execução e converte exceções
// inesperadas em falha tipada. NÃO publica estado para a interface — o módulo
// `widgets` fornece o adaptador de [Observable] para o `ValueListenable`.
//
// Dependências: [Observable] e [IResult], ambos do mesmo módulo.

import 'observable.dart';
import 'result.dart';

/// Ação assíncrona executada por um [Command].
typedef CommandAction<TSuccess, TFailure, TParam> =
    Future<IResult<TSuccess, TFailure>> Function(TParam? param);

/// Converte uma exceção inesperada na falha tipada do [Command].
typedef CommandExceptionMapper<TFailure> = TFailure Function(
  Object error,
  StackTrace stackTrace,
);

/// Marcador para comandos que não recebem parâmetro.
class NoParam {
  const NoParam();
}

/// Encapsula uma ação assíncrona e expõe seu estado de execução.
///
/// Falhas esperadas são devolvidas pela ação em [IResult]. Exceções inesperadas
/// são convertidas por [mapException], definido pelo consumidor. Cada estado é
/// um [Observable], então a UI pode reagir por `ValueListenable` através do
/// adaptador do módulo `widgets`, sem que este padrão dependa do framework.
class Command<TSuccess, TFailure, TParam> {
  Command(
    this._action, {
    required this._mapException,
  }) : isExecuting = Observable(false),
       canExecute = Observable(true),
       result = Observable<IResult<TSuccess, TFailure>?>(null);

  final CommandAction<TSuccess, TFailure, TParam> _action;
  final CommandExceptionMapper<TFailure> _mapException;

  /// `true` enquanto a ação awaitada está em curso.
  final Observable<bool> isExecuting;

  /// Quando `false`, [run] não inicia a ação. Controlado pelo consumidor.
  final Observable<bool> canExecute;

  /// Último resultado publicado; `null` antes da primeira execução.
  final Observable<IResult<TSuccess, TFailure>?> result;

  bool _isRunning = false;
  bool _isDisposed = false;

  /// Executa a ação se habilitada; chamadas concorrentes são ignoradas.
  Future<void> run([TParam? param]) async {
    _ensureNotDisposed();
    if (!canExecute.value || _isRunning) {
      return;
    }

    _isRunning = true;
    isExecuting.value = true;
    result.value = null;
    try {
      final outcome = await _action(param);
      if (_isDisposed) {
        return;
      }
      result.value = outcome;
    } catch (error, stackTrace) {
      if (_isDisposed) {
        return;
      }
      result.value = Failure(_mapException(error, stackTrace));
    } finally {
      _isRunning = false;
      isExecuting.value = false;
    }
  }

  /// Libera os observáveis e ignora a publicação de um comando ainda em curso.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    isExecuting.dispose();
    canExecute.dispose();
    result.dispose();
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('Command já foi descartado.');
    }
  }
}

/// Extensoes ergonomicas para criacao e execucao de [Command].
extension DnoCommandActionExtension<TSuccess, TFailure, TParam>
    on Future<IResult<TSuccess, TFailure>> Function(TParam? param) {
  /// Cria um [Command] a partir de uma acao com parametro.
  Command<TSuccess, TFailure, TParam> toCommand({
    required CommandExceptionMapper<TFailure> mapException,
  }) => Command<TSuccess, TFailure, TParam>(this, mapException: mapException);
}

extension DnoCommandNoParamActionExtension<TSuccess, TFailure>
    on Future<IResult<TSuccess, TFailure>> Function() {
  /// Cria um [Command] a partir de uma acao sem parametros.
  Command<TSuccess, TFailure, void> toCommand({
    required CommandExceptionMapper<TFailure> mapException,
  }) => Command<TSuccess, TFailure, void>(
    (_) => this(),
    mapException: mapException,
  );
}

extension DnoCommandExecutionExtension<TSuccess, TFailure, TParam>
    on Command<TSuccess, TFailure, TParam> {
  /// Executa o comando e retorna o resultado obtido.
  Future<IResult<TSuccess, TFailure>?> execute([TParam? param]) async {
    await run(param);
    return result.value;
  }

  /// Dispara callback se o resultado atual for [Success].
  void whenSuccess(void Function(TSuccess value) callback) {
    if (result.value case Success(value: final v)) {
      callback(v);
    }
  }

  /// Dispara callback se o resultado atual for [Failure].
  void whenFailure(void Function(TFailure failure) callback) {
    if (result.value case Failure(value: final f)) {
      callback(f);
    }
  }
}

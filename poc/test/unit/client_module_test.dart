import 'package:flutter_test/flutter_test.dart';
import 'package:poc/core/result.dart';
import 'package:poc/modules/clients/data/.index.dart';
import 'package:poc/modules/clients/domain/.index.dart';
import 'package:poc/modules/clients/features/.index.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(AppResult<T> result) {
  expect(result, isA<Success<T, AppFailure>>());
  return (result as Success<T, AppFailure>).value;
}

/// Codigo de um `Fail` (falha o teste se for `Ok`).
String _code<T>(AppResult<T> result) {
  expect(result, isA<Failure<T, AppFailure>>());
  return (result as Failure<T, AppFailure>).code;
}

/// Fachada sobre store em memoria (sem latencia).
IClientUseCases _useCases([InMemoryClientStore? store]) =>
    DefaultClientUseCases(
      clients: store ?? InMemoryClientStore(latency: Duration.zero),
    );

void main() {
  group('CreateClientCommand', () {
    test('cria cliente valido com id gerado', () async {
      final useCases = _useCases();

      final client = _ok(
        await useCases.createClient(name: 'Empresa X', phone: '11988887777'),
      );

      expect(client.id, isNonZero);
      expect(client.name, 'Empresa X');
      expect((await useCases.listClients()), hasLength(1));
    });

    test('telefone invalido falha sem persistir', () async {
      final useCases = _useCases();

      final result = await useCases.createClient(name: 'Empresa X', phone: '1');

      expect(_code(result), ClientFailureCodes.phoneInvalid);
      expect(await useCases.listClients(), isEmpty);
    });
  });

  group('UpdateClientCommand', () {
    test('edita nome e telefone do cliente existente', () async {
      final useCases = _useCases();
      final created = _ok(
        await useCases.createClient(name: 'Empresa X', phone: '11988887777'),
      );

      final updated = _ok(
        await useCases.updateClient(
          created.id,
          name: 'Empresa Y',
          phone: '11977776666',
        ),
      );

      expect(updated.id, created.id);
      expect(updated.name, 'Empresa Y');
      final stored = await useCases.listClients();
      expect(stored.single.name, 'Empresa Y');
    });

    test('id inexistente falha com CLIENT_NOT_FOUND', () async {
      final useCases = _useCases();

      final result = await useCases.updateClient(99, name: 'X');

      expect(_code(result), ClientFailureCodes.notFound);
    });

    test('telefone invalido na edicao mantem o registro anterior', () async {
      final useCases = _useCases();
      final created = _ok(
        await useCases.createClient(name: 'Empresa X', phone: '11988887777'),
      );

      final result = await useCases.updateClient(created.id, phone: '1');

      expect(_code(result), ClientFailureCodes.phoneInvalid);
      expect((await useCases.listClients()).single.phone, '11988887777');
    });
  });

  group('IClientUseCases (listagem)', () {
    test('busca por nome filtra sem diferenciar caixa', () async {
      final useCases = _useCases();
      await useCases.createClient(name: 'Empresa Alfa', phone: '11988887777');
      await useCases.createClient(name: 'Beta Ltda', phone: '11977776666');

      final all = await useCases.listClients();
      final filtered = await useCases.listClients(search: 'alfa');

      expect(all, hasLength(2));
      expect(filtered, hasLength(1));
      expect(filtered.single.name, 'Empresa Alfa');
    });

    test('store com seedDemo nasce com cliente de demonstracao', () async {
      final useCases = _useCases(
        InMemoryClientStore(latency: Duration.zero, seedDemo: true),
      );

      expect((await useCases.listClients()).single.name, 'Cliente Demo');
    });
  });

  group('Client (agregado)', () {
    test('telefone invalido reprova com CLIENT_PHONE_INVALID', () {
      final client = Client.create(name: 'Cliente', phone: '123');

      expect(client, isA<Failure<Client, AppFailure>>());
      expect(
        (client as Failure<Client, AppFailure>).code,
        ClientFailureCodes.phoneInvalid,
      );
    });

    test('nome vazio reprova com CLIENT_NAME_EMPTY', () {
      final client = Client.create(name: '  ', phone: '11988887777');

      expect(client, isA<Failure<Client, AppFailure>>());
      expect(
        (client as Failure<Client, AppFailure>).code,
        ClientFailureCodes.nameEmpty,
      );
    });

    test('valido normaliza telefone e nasce com id transiente', () {
      final client = _ok(
        Client.create(name: ' Cliente ', phone: '(11) 98888-7777'),
      );

      expect(client.id, 0);
      expect(client.name, 'Cliente');
      expect(client.phone, '11988887777');
    });
  });

  group('InMemoryClientStore', () {
    test('save gera id e listClients devolve o cliente', () async {
      final store = InMemoryClientStore(latency: Duration.zero);

      final saved = await store.saveClient(
        _ok(Client.create(name: 'Cliente', phone: '11988887777')),
      );

      expect(saved.id, 1);
      expect((await store.listClients()).single.name, 'Cliente');
      expect(await store.findClientById(saved.id), isNotNull);
    });

    test('findClientById ausente devolve null', () async {
      final store = InMemoryClientStore(latency: Duration.zero);

      expect(await store.findClientById(99), isNull);
    });
  });
}

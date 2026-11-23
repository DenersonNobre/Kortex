# Épico 09: Coleções Reativas (`KortexList` & `KortexMap`) (`EPIC09`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC09` |
| **Dependências Diretas** | `EPIC04` |
| **Prioridade** | Alta (Extração `synapx-kortex-extraction.md`) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Implementar `KortexList<E>` (`IKortexReadonlyList<E>`) e `KortexMap<K, V>` (`IKortexReadonlyMap<K, V>`) em `lib/src/reactive/` (Dart puro), com encapsulamento somente-leitura (`UnmodifiableListView`/`UnmodifiableMapView`), no-op em mutações idempotentes, consolidação via `kortexBatch` e bloqueio pós-`dispose` (`INV-01`).

- **Incluso**: `lib/src/reactive/kortex_list.dart`, `lib/src/reactive/kortex_map.dart`, reexportação em `reactive.dart`/`lib/kortex.dart` e testes focados em `test/`.
- **Não Incluso / Fora do Escopo**: `KortexEffect.once`, `throttle`, `runIfActive` (aguardam demanda real na PoC) e roteamento/Material.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-09.01** | `IKortexReadonlyList` e `KortexList<E>` | Nenhuma | `Concluído` |
| **UC-09.02** | `IKortexReadonlyMap`, `KortexMap<K, V>` e exportação pública | `UC-09.01` | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] `UC-09.01` e `UC-09.02` implementados sob TDD Red-Before-Green.
- [x] Zero imports Flutter em `lib/src/reactive/` (`INV-05`).
- [x] `flutter analyze` e `flutter test` verdes (exit code 0).
- [x] `CHANGELOG.md`, `docs/plan/README.md` e status do épico atualizados no mesmo commit.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-09.01 — `IKortexReadonlyList` e `KortexList<E>`

- **Identificador**: `UC-09.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter
- **Eu quero** manipular listas reativas mutáveis com visão somente-leitura encapsulada
- **Para que** adições, remoções e operações em lote notifiquem a UI sem cópias manuais nem vazamento de mutabilidade

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Operações, no-op, batch e pós-dispose em KortexList
  Dado uma KortexList inicializada com <inicial>
  Quando ocorre <operacao>
  Então o resultado observado é <resultado>

  Exemplos:
    | inicial | operacao | resultado |
    | [1, 2] | remove(99) ou clear() em lista vazia | 0 notificações (no-op) |
    | [1] | addAll([2, 3, 4]) | 1 única notificação via kortexBatch |
    | [1, 2] | leitura de readonly.value e escrita após dispose() | UnmodifiableListView bloqueia mutação; pós-dispose lança StateError |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-09.01` | `INV-05` | Imports Flutter em `kortex_list.dart` | `0` | `flutter analyze` / grep |

---

### Caso de Uso UC-09.02 — `IKortexReadonlyMap`, `KortexMap<K, V>` e Exportação Pública

- **Identificador**: `UC-09.02`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter
- **Eu quero** manipular mapas reativos com visão somente-leitura encapsulada e acesso via `package:kortex/kortex.dart`
- **Para que** estados indexados por chave sejam reativos, testáveis e livres de mutação externa

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Operações, no-op, batch e pós-dispose em KortexMap
  Dado um KortexMap inicializado com <inicial>
  Quando ocorre <operacao>
  Então o resultado observado é <resultado>

  Exemplos:
    | inicial | operacao | resultado |
    | {'a': 1} | map['a'] = 1 ou remove('b') | 0 notificações (no-op) |
    | {} | addAll({'a': 1, 'b': 2}) | 1 única notificação via kortexBatch |
    | {'a': 1} | leitura de readonly.value e escrita após dispose() | UnmodifiableMapView bloqueia mutação; pós-dispose lança StateError |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-09.02` | `INV-01` | Acesso pós-dispose lança `StateError` | `100%` | `flutter test` |

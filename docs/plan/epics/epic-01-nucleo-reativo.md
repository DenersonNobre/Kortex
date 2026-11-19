# Épico 01: Núcleo Reativo em Dart Puro (`EPIC01`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC01` |
| **Dependências Diretas** | `EPIC00` |
| **Prioridade** | Crítica (Core Domain — Dart Puro) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Pendente` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Implementar todo o núcleo reativo em `lib/src/reactive/` em Dart puro (`INV-05`), cobrindo ciclo de vida explícito, rastreamento de dependências, lotes transacionais, sinais, computados e efeitos.

- **Incluso**: `IKortexDisposable`, `KortexDisposeBag`, `IKortexController`, `IKortexObserver`, `IKortexReactiveNode`, `KortexTracker`, `kortexBatch`, `kortexUntracked`, `IKortexReadonlySignal`, `KortexSignal`, `KortexComputed`, `KortexEffect` (com `onCleanup`, `debounce` e guarda `_isRunning`) e extensões/typedefs da camada.
- **Não Incluso / Fora do Escopo**: primitivas assíncronas (`EPIC02`) e widgets/escopo Flutter (`EPIC03`/`EPIC04`).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-01.01** | Descarte composto (`IKortexDisposable`, `KortexDisposeBag`, `IKortexController`) | Nenhuma | `Pendente` |
| **UC-01.02** | Grafo de observação, `kortexBatch`, `kortexUntracked` e `KortexSignal` | `UC-01.01` | `Pendente` |
| **UC-01.03** | Derivação preguiçosa (`KortexComputed`) e efeitos (`KortexEffect`) | `UC-01.02` | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Todos os Casos de Uso (`UC-01.01..03`) implementados sob TDD Red-Before-Green.
- [ ] Zero imports de `package:flutter/` em `lib/src/reactive/` (`INV-05`).
- [ ] `flutter analyze` e `flutter test` verdes (exit code 0).

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-01.01 — Descarte Composto & `IKortexController`

- **Identificador**: `UC-01.01`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter
- **Eu quero** agrupar recursos descartáveis em `KortexDisposeBag` e `IKortexController`
- **Para que** meus controllers liberem todos os sinais e efeitos em ordem LIFO sem `onInit` mágico

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Descarte determinístico em KortexDisposeBag e IKortexController
  Dado um controller com recursos registrados via autoDispose em <estado_inicial>
  Quando dispose() for chamado <vezes>
  Então os recursos são descartados em ordem reversa com isDisposed igual a <disposed>

  Exemplos:
    | estado_inicial | vezes | disposed |
    | ativo com 2 itens | 1 | true (LIFO) |
    | já descartado | 2 | true (idempotente) |
    | bag já descartado + add novo item | 1 | item novo descartado imediatamente |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-01.01` | `NFR-03` | Imports Flutter em `reactive/` | `0` | `flutter analyze` / grep |

---

### Caso de Uso UC-01.02 — `KortexTracker`, `kortexBatch`, `kortexUntracked` e `KortexSignal`

- **Identificador**: `UC-01.02`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** desenvolvedor Dart/Flutter
- **Eu quero** sinais mutáveis com visão somente-leitura (`IKortexReadonlySignal`), `peek()`, `equals` customizado e `kortexBatch`
- **Para que** alterações de estado sejam encapsuladas, livres de glitches e seguras pós-`dispose`

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Mutação, igualdade, batch e bloqueio pós-dispose em KortexSignal
  Dado um KortexSignal inicializado com <inicial>
  Quando ocorre a operação <operacao> com valor <novo>
  Então o resultado observado é <resultado>

  Exemplos:
    | inicial | operacao | novo | resultado |
    | 10 | atribuir mesmo valor | 10 | 0 notificações |
    | 10 | 2 escritas em kortexBatch | 20 -> 30 | 1 notificação com 30 |
    | 10 | ler/escrever após dispose() | 99 | lança StateError |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-01.02` | `INV-01` | Acesso pós-dispose lança `StateError` | `100%` | `flutter test` |

---

### Caso de Uso UC-01.03 — `KortexComputed` e `KortexEffect`

- **Identificador**: `UC-01.03`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** desenvolvedor Dart/Flutter
- **Eu quero** valores derivados preguiçosos (`KortexComputed`) e efeitos colaterais em Dart puro (`KortexEffect`) com `onCleanup`, `debounce` e guarda de reentrância
- **Para que** derivações não recalculem sem leitura e efeitos não vazem memória nem entrem em loop

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Avaliação lazy de KortexComputed e ciclo de KortexEffect
  Dado um nó reativo configurado em <modo>
  Quando a dependência muda para <valor>
  Então o comportamento executado é <comportamento>

  Exemplos:
    | modo | valor | comportamento |
    | KortexComputed sem leitor | 2 | marca dirty sem recomputar até leitura |
    | KortexEffect com onCleanup | 3 | executa cleanup anterior antes de reexecutar |
    | KortexEffect escrevendo próprio sinal | 4 | ignora auto-reentrada síncrona (_isRunning) |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-01.03` | `INV-04` | Assinaturas removidas após `dispose()` | `100%` | `flutter test` |

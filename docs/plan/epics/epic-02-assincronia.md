# Épico 02: Assincronia, Streams & Comandos (`EPIC02`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC02` |
| **Dependências Diretas** | `EPIC01` |
| **Prioridade** | Alta |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Implementar as primitivas assíncronas em Dart puro (`KortexResource<T>`, `KortexStreamResource<T>`, `toStream()` e `KortexCommand<TParam, TResult>`) com representação selada `IKortexAsyncState<T>` e proteção contra race conditions e ações concorrentes.

- **Incluso**: `IKortexAsyncState<T>` (`KortexAsyncLoading` com `previousValue`, `KortexAsyncData`, `KortexAsyncError`), `KortexResource<T>`, `KortexStreamResource<T>`, `IKortexReadonlySignal<T>.toStream()` e `KortexCommand<TParam, TResult>`.
- **Não Incluso / Fora do Escopo**: widgets de UI (`KortexResourceBuilder`, tratado no `EPIC04`).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-02.01** | `IKortexAsyncState` e `KortexResource` (race condition + `previousValue`) | Nenhuma | `Concluído` |
| **UC-02.02** | `KortexStreamResource`, `toStream()` e `KortexCommand` | `UC-02.01` | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] `UC-02.01` e `UC-02.02` cobertos por testes de concorrência (`Completer`/`StreamController`) sob TDD.
- [x] Zero imports Flutter em `lib/src/reactive/`.
- [x] `flutter analyze` e `flutter test` verdes.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-02.01 — `IKortexAsyncState` e `KortexResource`

- **Identificador**: `UC-02.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter
- **Eu quero** gerenciar carregamentos assíncronos preservando `previousValue` em `refresh()` e descartando respostas tardias
- **Para que** a tela não pisque em atualizações e chamadas antigas nunca sobrescrevam dados novos ou pós-`dispose`

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Controle de concorrência e previousValue em KortexResource
  Dado um KortexResource em estado <estado_inicial>
  Quando ocorre <evento>
  Então o estado final é <estado_final>

  Exemplos:
    | estado_inicial | evento | estado_final |
    | KortexAsyncData(1) | refresh() em voo | KortexAsyncLoading(previousValue: 1) |
    | refresh #1 e #2 concorrentes | #1 resolve depois de #2 | mantém resultado de #2 (descarta #1) |
    | refresh() em voo | dispose() antes de resolver | resposta tardia ignorada; novo refresh lança StateError |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-02.01` | `INV-02` | Atualizações tardias após `dispose()` | `0` | `flutter test` |

---

### Caso de Uso UC-02.02 — `KortexStreamResource`, `toStream()` e `KortexCommand`

- **Identificador**: `UC-02.02`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor Dart/Flutter
- **Eu quero** integrar `Stream<T>` com cancelamento automático e executar mutações com trava de reentrância via `KortexCommand`
- **Para que** assinaturas de stream não vazem memória e cliques duplos não disparem ações duplicadas

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Ciclo de StreamResource e trava de reentrância em KortexCommand
  Dado uma primitiva assíncrona em <cenario>
  Quando ocorre <acao>
  Então o resultado observado é <resultado>

  Exemplos:
    | cenario | acao | resultado |
    | KortexStreamResource ativo | dispose() | StreamSubscription cancelada automaticamente |
    | KortexCommand com isExecuting == true | execute(param) concorrente | retorna null sem disparar 2a execução |
    | IKortexReadonlySignal.toStream() | cancelar assinatura | observador removido do sinal |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-02.02` | `INV-02` | Execuções concorrentes indevidas no `Command` | `0` | `flutter test` |

# Kortex (`v0.2.1`) — Especificação Técnica de Domínio

> **Arquiteto (responsável)**: Denerson Nobre  
> **Versão**: `0.2.1` | **Data**: `2026-11-22`  
> **PRD de Referência**: [PRD.md](../product/PRD.md)

## Regras de Negócio Executáveis (Obrigatório)

| ID | Regra | Entrada | Saída | Exceções | Rastreabilidade |
| --- | --- | --- | --- | --- | --- |
| `RN-01` | Sinal mutável só notifica quando `equals` retorna `false` | `signal.value = next` (com `equals` padrão `==` ou customizado) | Sem notificação se igual; notifica observadores se diferente | `StateError` se `isDisposed == true` | `INV-01, RF-01` |
| `RN-02` | `kortexBatch` consolida notificações sem glitches | 2+ mutações dentro de `kortexBatch(() { ... })` | Observadores são notificados uma única vez ao sair do batch mais externo | Se exceção ocorrer no bloco, decrementa profundidade e faz flush/limpeza | `INV-04, RF-03` |
| `RN-03` | `Computed` lazy e `Effect` com `onCleanup` / `debounce` | Alteração de dependência observada | `Computed` marca `_isDirty = true`; `Effect` executa `onCleanup` anterior, cancela timer pendente e reexecuta (após `debounce`, se definido) | `StateError` se `Computed` lido após `dispose()` | `INV-01, INV-04, RF-02, RF-03` |
| `RN-04` | `Resource` preserva `previousValue` / descarta tardias; `StreamResource` cancela assinatura; `Command` bloqueia reentrância | `refresh()` concorrente / evento de `Stream` / `execute()` com `isExecuting == true` | `Resource` mantém `previousValue` em `Loading` durante `refresh` e ignora resultado antigo; `StreamResource` cancela `StreamSubscription` no `dispose()`; `Command` ignora disparo concorrente | `StateError` se chamado após `dispose()` | `INV-02, RF-04` |
| `RN-05` | Resolução hierárquica e entre irmãos em `KortexScope` | `readKortex<T>()` / `watchKortex<T>()` ou leitura entre providers irmãos | Instância `T` (com `override` aplicado se houver; inicializa se `lazy`) | `StateError` se `T` ausente ou dependência circular detectada | `INV-03, INV-06, INV-07, RF-06` |
| `RN-06` | `IKortexPage`, `KortexWatch`, `KortexSelector` e `KortexListener` respeitam ciclo de vida | Mudança de sinal lido/selecionado vs widget desmontado | `IKortexPage` resolve `TController` via `BuildContext`; `Watch` reconstrói (mantendo `child`); `Selector` só reconstrói se seleção mudar; `Listener` avalia `watch` em `initState` e dispara `listener` fora do `build` apenas quando `watch` muda e `mounted == true` | Nenhuma chamada a `setState` ou `listener` após `!mounted` | `INV-04, RF-07` |
| `RN-07` | Coleções reativas (`KortexList`, `KortexMap`, `KortexSet`) respeitam no-op, batch e encapsulamento | Mutação no-op (`remove` ausente, `clear()` vazio, `map[k] = mesmoValor`, `set.add` já presente) vs mutação efetiva | No-op não notifica; mutações compostas (`addAll`, `removeWhere`) notificam 1x via `kortexBatch`; `readonly` expõe visão imutável | `StateError` em leitura/escrita após `dispose()` | `INV-01, INV-04, INV-05` |

---

## 1. Visão Geral & Bounded Context

- **Propósito do Sistema**: Fornecer primitivas reativas granulares e contratos de arquitetura em Dart puro (`reactive/`), provisão escopada com ciclo de vida determinístico atrelado à árvore de widgets (`scope/`) e widgets reativos `StatelessWidget`-first (`widgets/`), sem dependências externas e sem estado global implícito.
- **Fronteiras & Limites**:
  - **DENTRO do escopo**: `KortexSignal<T>`, `IKortexReadonlySignal<T>`, `KortexComputed<T>`, `KortexEffect`, `kortexBatch`, `kortexUntracked`, `KortexResource<T>`, `KortexStreamResource<T>`, `IKortexAsyncState<T>`, `KortexCommand<TParam, TResult>`, `IKortexDisposable`, `KortexDisposeBag`, `IKortexController`, `KortexProvider<T>`, `KortexScope`, extensões de `BuildContext`, `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener`, `KortexResourceBuilder<T>` e pontes `Listenable`.
  - **FORA do escopo**: Service Locator global, EventBus global, roteador próprio, helpers sem `BuildContext` (`dialog`/`snackbar`/`theme`), HTTP, persistência, i18n, logger global estático, abstrações cerimoniais de `Repository`/`DataSource` e code generation.

### Arquitetura e Estrutura de Diretórios

```text
kortex/
├── pubspec.yaml
├── lib/
│   ├── kortex.dart
│   └── src/
│       ├── reactive/
│       │   ├── kortex_disposable.dart
│       │   ├── kortex_controller.dart
│       │   ├── kortex_observer.dart
│       │   ├── kortex_signal.dart
│       │   ├── kortex_computed.dart
│       │   ├── kortex_effect.dart
│       │   ├── kortex_list.dart
│       │   ├── kortex_map.dart
│       │   ├── kortex_set.dart
│       │   ├── kortex_resource.dart
│       │   ├── kortex_stream_resource.dart
│       │   └── kortex_command.dart
│       ├── scope/
│       │   ├── kortex_provider.dart
│       │   ├── kortex_scope.dart
│       │   └── kortex_context_extensions.dart
│       └── widgets/
│           ├── kortex_page.dart
│           ├── kortex_watch.dart
│           ├── kortex_selector.dart
│           ├── kortex_listener.dart
│           ├── kortex_resource_builder.dart
│           └── kortex_listenable_adapter.dart
└── test/
    └── kortex_test.dart
```

### Fronteiras de Camada

- `lib/src/reactive/` (**Dart puro**): grafo de observação, sinais, computados, efeitos, batches, recursos, comandos, descarte composto e `IKortexController`. Proibido importar `package:flutter/widgets.dart` ou usar `BuildContext`.
- `lib/src/scope/` (**Flutter SDK**): provisão (`eager`/`lazy`/`.value`), resolução hierárquica e entre irmãos, `KortexScope.capture`, detecção de ciclos, `overrides` de teste e descarte determinístico vinculado ao `State` de `KortexScope`.
- `lib/src/widgets/` (**Flutter SDK**): `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener`, `KortexResourceBuilder<T>` e adaptadores `Listenable`.
- `lib/kortex.dart`: barrel file reexportando apenas a API pública pretendida (ocultando coordenadores internos como `KortexTracker`).

---

## 2. Linguagem Ubíqua (Glossário Canônico)

Regra obrigatória de nomenclatura (`flutter.md`): **toda interface, classe abstrata ou `sealed` inicia com prefixo `I` (`IKortex*`)**; classes concretas iniciam com `Kortex*` e funções utilitárias com `kortex*`.

| Termo de Domínio | Termo Técnico no Código | Definição Rígida |
| --- | --- | --- |
| **Descartável** | `IKortexDisposable` | Interface explícita com `void dispose()` para liberação determinística de recursos (inclusive serviços/datasources no `KortexScope`). |
| **Controlador** | `IKortexController` | Classe abstrata em Dart puro com `KortexDisposeBag` integrado e `onDispose()` (inicialização exclusivamente no construtor). |
| **Observador** | `IKortexObserver` | Interface que recebe notificações de alteração (`onRead`) de um nó observado. |
| **Nó Reativo** | `IKortexReactiveNode` | Interface de fonte observável que gerencia observadores e descarte (`dispose`). |
| **Sinal Somente-Leitura** | `IKortexReadonlySignal<T>` | Visão pública de leitura (`value` e `peek()`) sem permissão de escrita, garantindo encapsulamento. |
| **Sinal Mutável** | `KortexSignal<T>` | Contêiner de valor mutável com igualdade configurável (`equals`) e notificação reativa. |
| **Valor Computado** | `KortexComputed<T>` | Valor derivado `lazy` com cache e invalidação em cascata (implementa `IKortexReadonlySignal<T>`). |
| **Efeito Reativo** | `KortexEffect` | Reação automática a sinais em Dart puro com suporte a `onCleanup`, `debounce` e `dispose()` explícito. |
| **Lote Transacional** | `kortexBatch` | Escopo síncrono que adia e deduplica notificações até a conclusão da transação. |
| **Leitura Não Rastreada** | `kortexUntracked` / `peek()` | Leitura do valor atual sem registrar o nó no `KortexTracker` ativo. |
| **Estado Assíncrono** | `IKortexAsyncState<T>` | Classe selada (`sealed`) representando `KortexAsyncLoading<T>`, `KortexAsyncData<T>` ou `KortexAsyncError<T>`. |
| **Recurso Assíncrono** | `KortexResource<T>` | Controlador de carga assíncrona (`loading` com `previousValue` opcional / `data` / `error`) com descarte de respostas tardias. |
| **Recurso de Stream** | `KortexStreamResource<T>` | Ponte reativa para `Stream<T>` com emissão em `IKortexAsyncState<T>` e cancelamento automático no `dispose()`. |
| **Comando Assíncrono** | `KortexCommand<TParam, TResult>` | Encapsulador de ação/mutação assíncrona com `isExecuting`, `state` e trava contra reentrância. |
| **Leitor de Escopo** | `IKortexScopeReader` | Interface explícita para resolução de dependências dentro de `KortexProvider.create`. |
| **Provedor** | `KortexProvider<T>` | Definição imutável de criação (`create`), `lazy`, `.value` e `dispose` para um tipo `T`. |
| **Escopo de Árvore** | `KortexScope` | Widget que gerencia instâncias, resolução hierárquica/entre irmãos, `capture`, `overrides` e `dispose`. |
| **Página Stateless** | `IKortexPage<TController>` | Classe abstrata `StatelessWidget` que resolve `TController` via `BuildContext` e delega para `buildPage`. |
| **Ouvinte de UI** | `KortexListener` | Widget que executa callbacks imperativos com `BuildContext` real fora da fase de `build`. |

---

## 3. Invariantes de Domínio (Regras Inegociáveis)

- **INV-01 (Bloqueio Pós-Dispose)**: Ler ou escrever em `KortexSignal<T>`, `KortexComputed<T>`, `KortexResource<T>`, `KortexStreamResource<T>` ou `KortexCommand<TParam, TResult>` após `dispose()` deve lançar `StateError` explícito.
- **INV-02 (Descarte de Respostas Tardias)**: `KortexResource<T>`, `KortexStreamResource<T>` e `KortexCommand<TParam, TResult>` devem ignorar silenciosamente conclusões/eventos superados por `dispose()` (e por novo `refresh()` / `restart()`).
- **INV-03 (Falha Explícita em Escopo Ausente)**: `readKortex<T>()` e `watchKortex<T>()` devem lançar `StateError` indicando o tipo `T` ausente na árvore ancestral.
- **INV-04 (Limpeza Determinística de Assinaturas)**: Todo observador (`KortexComputed`, `KortexEffect`, `KortexWatch`, `KortexSelector`, `KortexListener`) deve limpar vínculos antigos antes de reavaliar dependências e no próprio `dispose()`.
- **INV-05 (Pureza da Camada Reativa)**: Nenhum arquivo em `lib/src/reactive/` pode importar `package:flutter/widgets.dart` ou depender de `BuildContext`.
- **INV-06 (Zero Estado Global / Zero Mágica)**: Nenhuma resolução ocorre fora de `KortexScope` + `BuildContext`; nenhum `dispose` automático ocorre por reflexão ou convenção implícita (apenas callback explícito ou contrato tipado `IKortexDisposable`).
- **INV-07 (Detecção de Dependência Circular)**: Se um `KortexProvider<A>` depender de `B` e `B` depender de `A` no mesmo `KortexScope`, a inicialização deve falhar imediatamente com `StateError` descritivo (em vez de `StackOverflowError`).
- **INV-08 (Convenção `I-`)**: Toda interface, classe abstrata ou `sealed` pública do pacote inicia com prefixo `I`.

---

## 4. Especificação dos Contratos e Tipos Públicos

### 4.1 Camada Reativa (`lib/src/reactive/`)

#### `IKortexDisposable` e `KortexDisposeBag` (`kortex_disposable.dart`)

- `abstract interface class IKortexDisposable`: define `void dispose()`.
- `class KortexDisposeBag implements IKortexDisposable`:
  - `bool get isDisposed`
  - `T add<T extends IKortexDisposable>(T item)`: registra `item` (ou executa `item.dispose()` imediatamente se o bag já estiver descartado).
  - `void addCallback(void Function() onDispose)`: registra callback arbitrário de limpeza.
  - `void dispose()`: executa `dispose` em ordem reversa de registro (LIFO) em modo **best-effort** (todos os callbacks executam mesmo se um lançar, preservando o primeiro erro via `Error.throwWithStackTrace`) e limpa a coleção (idempotente).
  - `KortexDebug` (`kortex_debug.dart`): hook estático opt-in (`IKortexDebugObserver? observer`) protegido por `assert(...)` (custo zero em release, Dart puro `INV-05`) — **única exceção justificada a `INV-06`** por ser estritamente de diagnóstico em debug.

#### `IKortexController` (`kortex_controller.dart`)

- `abstract class IKortexController implements IKortexDisposable`:
  - Mantém `final KortexDisposeBag disposeBag = KortexDisposeBag();` e `bool get isDisposed => disposeBag.isDisposed;`.
  - Helper protegido `T autoDispose<T extends IKortexDisposable>(T item) => disposeBag.add(item);`.
  - Gancho opcional `void onDispose() {}` (invocado em `dispose()` antes de `disposeBag.dispose()`).
  - Inicialização ocorre exclusivamente no construtor (sem `onInit()` mágico, mantendo testabilidade direta fora do `KortexScope`).
  - `@mustCallSuper void dispose()`: protege contra reexecução idempotente, chama `onDispose()` e `disposeBag.dispose()`.

#### `IKortexObserver`, `IKortexReactiveNode` e `KortexTracker` (`kortex_observer.dart`)

- `abstract interface class IKortexObserver`: `void onRead(IKortexReactiveNode node)`.
- `abstract interface class IKortexReactiveNode implements IKortexDisposable`:
  - `void addObserver(IKortexObserver observer)`
  - `void removeObserver(IKortexObserver observer)`
  - `void dispose()`
- `KortexTracker` (interno):
  - Pilha de rastreamento (`current`, `runWithObserver`, `recordRead`).
  - `untracked<T>(T Function() action)` e `batch(void Function() action)` com fila deduplicada.
- Helpers públicos expostos: `void kortexBatch(void Function() action)` e `T kortexUntracked<T>(T Function() action)`.

#### `IKortexReadonlySignal<T>` e `KortexSignal<T>` (`kortex_signal.dart`)

- `abstract interface class IKortexReadonlySignal<T> implements IKortexReactiveNode`:
  - `bool get isDisposed`
  - `T get value`: valida estado não descartado, registra leitura no `KortexTracker.recordRead(this)` e retorna o valor.
  - `T peek()`: valida estado não descartado e retorna o valor atual **sem** registrar leitura no `KortexTracker`.
- `class KortexSignal<T> implements IKortexReadonlySignal<T>`:
  - Construtor: `KortexSignal(T initialValue, {KortexEquals<T>? equals})`.
  - Helper: `KortexSignal<T> kortexSignal<T>(T initialValue, {KortexEquals<T>? equals})`.
  - `set value(T newValue)`, `void update(KortexUpdater<T> updater)`, `IKortexReadonlySignal<T> get readonly`, `void dispose()`.

#### `KortexComputed<T>` (`kortex_computed.dart`)

- Implementa `IKortexReadonlySignal<T>` e `IKortexObserver`.
- Construtor: `KortexComputed(T Function() compute, {KortexEquals<T>? equals})`.
- Helper: `KortexComputed<T> kortexComputed<T>(T Function() compute, {KortexEquals<T>? equals})`.
- Avaliação `lazy` com cache, `peek()`, `value`, `onRead` e `dispose()`.

#### `KortexEffect` (`kortex_effect.dart`)

- Implementa `IKortexObserver` e `IKortexDisposable`.
- Construtor: `KortexEffect(KortexEffectCallback effect, {Duration? debounce})`.
- Helper: `KortexEffect kortexEffect(KortexEffectCallback effect, {Duration? debounce})`.
- Executa na criação sob `KortexTracker.runWithObserver`, suporta `onCleanup`, `debounce` via `Timer` (`dart:async`) e `dispose()` explícito; mantém guarda `_isRunning` para ignorar auto-notificações disparadas durante sua própria execução síncrona.

#### `IKortexReadonlyList<E>` e `KortexList<E>` (`kortex_list.dart`)

- `abstract interface class IKortexReadonlyList<E> implements IKortexReadonlySignal<List<E>>`:
  - Expõe `List<E> get value` e `List<E> peek()` retornando `UnmodifiableListView<E>` (impede mutação externa pela UI).
  - Expõe leituras rastreadas (`int get length`, `bool get isEmpty`, `bool get isNotEmpty`, `E operator [](int index)`).
- `class KortexList<E> extends ListBase<E> implements IKortexReadonlyList<E>`:
  - Construtor: `KortexList([Iterable<E> initial = const []])` e helper `KortexList<E> kortexList<E>([Iterable<E> initial = const []])`.
  - Expõe `IKortexReadonlyList<E> get readonly`.
  - No-op em `clear()` com lista vazia, `remove()` de item ausente e `this[i] = v` quando `this[i] == v`.
  - Operações em lote (`addAll`, `insertAll`, `removeWhere`, `retainWhere`, `sort`, `replaceAll`) executam sob `kortexBatch` para notificar uma única vez.
  - Leitura/escrita após `dispose()` lança `StateError` (`INV-01`).

#### `IKortexReadonlyMap<K, V>` e `KortexMap<K, V>` (`kortex_map.dart`)

- `abstract interface class IKortexReadonlyMap<K, V> implements IKortexReadonlySignal<Map<K, V>>`:
  - Expõe `Map<K, V> get value` e `Map<K, V> peek()` retornando `UnmodifiableMapView<K, V>` (impede mutação externa pela UI).
  - Expõe leituras rastreadas (`int get length`, `bool get isEmpty`, `bool get isNotEmpty`, `bool containsKey(Object? key)`, `V? operator [](Object? key)`).
- `class KortexMap<K, V> extends MapBase<K, V> implements IKortexReadonlyMap<K, V>`:
  - Construtor: `KortexMap([Map<K, V>? initial])` e helper `KortexMap<K, V> kortexMap<K, V>([Map<K, V>? initial])`.
  - Expõe `IKortexReadonlyMap<K, V> get readonly`.
  - No-op em `this[k] = v` quando `containsKey(k) && this[k] == v`, `remove(k)` de chave ausente e `clear()` com mapa vazio.
  - Operações em lote (`addAll`, `addEntries`, `removeWhere`, `updateAll`, `replaceAll`) executam sob `kortexBatch` para notificar uma única vez.
  - Leitura/escrita após `dispose()` lança `StateError` (`INV-01`).

#### `IKortexReadonlySet<E>` e `KortexSet<E>` (`kortex_set.dart`)

- `abstract interface class IKortexReadonlySet<E> implements IKortexReadonlySignal<Set<E>>`:
  - Expõe `Set<E> get value` e `Set<E> peek()` retornando `UnmodifiableSetView<E>` (impede mutação externa pela UI).
  - Expõe leituras rastreadas (`int get length`, `bool get isEmpty`, `bool get isNotEmpty`, `bool contains(Object? element)`).
  - Alias curto: `typedef IKortexSet<E> = IKortexReadonlySet<E>;`.
- `class KortexSet<E> extends SetBase<E> implements IKortexReadonlySet<E>`:
  - Construtor: `KortexSet([Iterable<E> initial = const []])` e helper `KortexSet<E> kortexSet<E>([Iterable<E> initial = const []])`.
  - Expõe `IKortexReadonlySet<E> get readonly`.
  - No-op em `add(e)` já presente, `remove(e)` ausente e `clear()` com conjunto vazio.
  - Operações em lote (`addAll`, `removeAll`, `retainAll`, `removeWhere`, `retainWhere`, `replaceAll`) executam sob `kortexBatch` para notificar uma única vez.
  - Leitura/escrita após `dispose()` lança `StateError` (`INV-01`).

#### `IKortexAsyncState<T>` e `KortexResource<T>` (`kortex_resource.dart`)

- `sealed class IKortexAsyncState<T>`:
  - `bool get isLoading => this is KortexAsyncLoading<T>`
  - `bool get isRefreshing` (`this is KortexAsyncLoading<T>` com `previousValue != null`)
  - `T? get valueOrNull`
  - `KortexAsyncLoading<T>({T? previousValue})`
  - `KortexAsyncData<T>(T value)`
  - `KortexAsyncError<T>(Object error, [StackTrace? stackTrace])`
- `KortexResource<T> implements IKortexDisposable`:
  - Construtor: `KortexResource(KortexAsyncLoader<T> loader, {bool immediate = true})`.
  - Helper: `KortexResource<T> kortexResource<T>(KortexAsyncLoader<T> loader, {bool immediate = true})`.
  - Expõe `IKortexReadonlySignal<IKortexAsyncState<T>> get state`, `Future<void> refresh()` e `void dispose()`.

#### `KortexStreamResource<T>` (`kortex_stream_resource.dart`)

- Implementa `IKortexDisposable`.
- Construtor: `KortexStreamResource(KortexStreamFactory<T> streamFactory, {bool immediate = true})`.
- Helper: `KortexStreamResource<T> kortexStreamResource<T>(KortexStreamFactory<T> streamFactory, {bool immediate = true})`.
- Expõe `IKortexReadonlySignal<IKortexAsyncState<T>> get state`, `void restart()` e `void dispose()`.
- Extensão em `IKortexReadonlySignal<T>`: `Stream<T> toStream()` — emite mudanças reativas como `Stream<T>` e cancela a observação automaticamente no `onCancel` da assinatura.

#### `KortexCommand<TParam, TResult>` (`kortex_command.dart`)

- Implementa `IKortexDisposable`.
- Construtor: `KortexCommand(KortexCommandAction<TParam, TResult> action)`.
- Helper: `KortexCommand<TParam, TResult> kortexCommand<TParam, TResult>(KortexCommandAction<TParam, TResult> action)`.
- Expõe `IKortexReadonlySignal<bool> get isExecuting`, `IKortexReadonlySignal<IKortexAsyncState<TResult>?> get state`, `Future<TResult?> execute(TParam param)` e `void dispose()`.

### 4.2 Camada de Escopo (`lib/src/scope/`)

#### `IKortexScopeReader` e `KortexProvider<T>` (`kortex_provider.dart`)

- `abstract interface class IKortexScopeReader`:
  - `T read<T>()`: resolve dependência no escopo atual (entre irmãos já declarados ou em inicialização) ou sobe pelos ancestrais via `BuildContext`.
- `KortexProvider<T>`:
  - Construtor padrão: `KortexProvider({required KortexCreate<T> create, KortexDispose<T>? dispose, bool lazy = false})`, onde `create` recebe apenas `IKortexScopeReader scope` (evitando ambiguidade com `BuildContext`).
  - Construtor de valor externo: `KortexProvider.value({required T value})` (não executa `dispose` ao desmontar o escopo).
  - Auto-dispose explícito: se `dispose` for omitido no construtor padrão e a instância implementar `IKortexDisposable` (o que inclui `IKortexController` e qualquer serviço/datasource que implemente o contrato), o `KortexScope` chama `instance.dispose()` automaticamente.

#### `KortexScope` (`kortex_scope.dart`)

- `StatefulWidget` recebendo `providers`, `overrides = const []` e `child`.
- **Resolução entre irmãos + Detecção de Ciclo (`INV-07`)**, suporte a **`lazy`**, **`KortexScope.capture({required BuildContext context, required Widget child})`** (para `showDialog` / `showModalBottomSheet` no `Overlay`), compatibilidade nativa com `Navigator` e rotas em shell, preservação das instâncias entre rebuilds do widget pai (usando `Key` quando reinicialização explícita for desejada) e `resolveKortexDependency<T>(BuildContext context, {required bool listen})`.

#### `KortexContextExtensions` (`kortex_context_extensions.dart`)

- `T readKortex<T>()`: `resolveKortexDependency<T>(this, listen: false)`.
- `T watchKortex<T>()`: `resolveKortexDependency<T>(this, listen: true)`.

### 4.3 Camada de Widgets (`lib/src/widgets/`)

#### `IKortexPage<TController extends IKortexController>` (`kortex_page.dart`)

- `abstract class IKortexPage<TController extends IKortexController> extends StatelessWidget`:
  - `const IKortexPage({super.key});`
  - `TController controllerOf(BuildContext context) => context.readKortex<TController>();`
  - `Widget buildPage(BuildContext context, TController controller);`
  - `@override Widget build(BuildContext context) => buildPage(context, controllerOf(context));`
- Permite que telas sejam escritas prioritariamente como `StatelessWidget` sem Service Locator global, mantendo resolução estrita via `BuildContext` e `KortexScope`.

#### `KortexWatch` (`kortex_watch.dart`)

- `StatefulWidget` com `KortexWatchBuilder builder` e `Widget? child` opcional.
- Limpa assinaturas antes de cada `build`, coleta nós via `KortexTracker.runWithObserver` e agenda `setState` respeitando `mounted` e `SchedulerBinding.instance.schedulerPhase`.

#### `KortexSelector<T>` (`kortex_selector.dart`)

- `StatefulWidget` com `selector`, `builder` (`KortexSelectorBuilder<T>`), `equals` (`KortexEquals<T>?`) e `Widget? child`.

#### `KortexListener<T>` (`kortex_listener.dart`)

- `StatefulWidget` para efeitos colaterais seguros na UI (`SnackBar`, `Navigator`, `showDialog`) com separação entre leitura pura e efeito:
  - `required T Function() watch`: avaliado em `initState` sob `KortexTracker.runWithObserver` para descobrir dependências e capturar o valor inicial sem disparar efeitos colaterais.
  - `required KortexContextListener<T> listener`: executado fora da fase de `build` apenas quando o valor de `watch()` muda segundo `equals` (ou logo após a montagem se `fireImmediately == true`), sempre verificando `mounted`.
  - `KortexEquals<T>? equals`
  - `bool fireImmediately = false`
  - `required Widget child`

#### `KortexResourceBuilder<T>` (`kortex_resource_builder.dart`)

- `StatelessWidget` genérico recebendo `resource`, `loading`, `error` (`KortexErrorWidgetBuilder`) e `data` (`KortexDataWidgetBuilder<T>`), fazendo pattern matching exaustivo em `IKortexAsyncState<T>`.

#### `KortexListenableAdapter` (`kortex_listenable_adapter.dart`)

- Extensão em `ValueListenable<T>`: `KortexListenableSignal<T> toKortexSignal()` (implementa `IKortexReadonlySignal<T>` e `IKortexDisposable`; seu `dispose()` apenas remove o listener, preservando a posse e o ciclo de vida do `ValueListenable<T>` original).
- Extensão em `Listenable` (cobrindo `ChangeNotifier`, `ScrollController`, `TabController`, etc.): `KortexListenableSignal<T> toKortexSignalWith<T>(T Function() read)` (nome distinto para evitar conflito de extensão com `ValueListenable<T>`; lê `read()` a cada notificação e remove o listener no `dispose()` sem descartar o `Listenable` original).
- Extensão em `IKortexReadonlySignal<T>`: `KortexSignalListenable toListenable()` (implementa `Listenable` e `IKortexDisposable`), ideal para `refreshListenable` de roteadores declarativos.

### 4.4 Typedefs e Extensions Ergonômicos

- **Typedefs (`reactive/`)**:
  - `KortexEquals<T> = bool Function(T previous, T next)`
  - `KortexUpdater<T> = T Function(T current)`
  - `KortexCleanup = void Function()`
  - `KortexEffectCleanupRegistrar = void Function(KortexCleanup cleanup)`
  - `KortexEffectCallback = void Function(KortexEffectCleanupRegistrar onCleanup)`
  - `KortexAsyncLoader<T> = Future<T> Function()`
  - `KortexStreamFactory<T> = Stream<T> Function()`
  - `KortexCommandAction<TParam, TResult> = Future<TResult> Function(TParam param)`
- **Typedefs (`scope/` e `widgets/`)**:
  - `KortexCreate<T> = T Function(IKortexScopeReader scope)`
  - `KortexDispose<T> = void Function(T instance)`
  - `KortexWatchBuilder = Widget Function(BuildContext context, Widget? child)`
  - `KortexSelectorBuilder<T> = Widget Function(BuildContext context, T value, Widget? child)`
  - `KortexContextListener<T> = void Function(BuildContext context, T value)`
  - `KortexErrorWidgetBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace)`
  - `KortexDataWidgetBuilder<T> = Widget Function(BuildContext context, T value)`
- **Extensions (`reactive/` e `widgets/`)**:
  - `KortexSignalExtension<T extends Object>` on `T`: `KortexSignal<T> get kortex` (bloqueia `null.kortex` em compilação; aceita primitivos, enums e objetos de domínio)
  - `KortexListExtension<E>` on `List<E>`: `KortexList<E> get kortexList`
  - `KortexMapExtension<K, V>` on `Map<K, V>`: `KortexMap<K, V> get kortexMap`
  - `KortexSetExtension<E>` on `Set<E>`: `KortexSet<E> get kortexSet`
  - Aliases curtos: `Kortex<T> = KortexSignal<T>`, `IKortex<T> = IKortexReadonlySignal<T>`, `IKortexList<E> = IKortexReadonlyList<E>`, `IKortexMap<K, V> = IKortexReadonlyMap<K, V>`, `IKortexSet<E> = IKortexReadonlySet<E>`
  - *(Nota: leitura de sinais usa exclusivamente `.value` / `.peek()`, e `IKortexAsyncState<T>` usa `switch` exaustivo nativo do Dart 3.)*

---

## 5. Portas & Interfaces de Extensibilidade

- **Observação e Ciclo de Vida**: `IKortexObserver`, `IKortexReactiveNode`, `IKortexReadonlySignal<T>`, `IKortexDisposable`, `IKortexController`.
- **Provisão e UI**: `KortexProvider<T>`, `IKortexScopeReader`, `IKortexPage<TController>`.

---

## 6. Taxonomia de Falhas & Tratamento de Erros

| Cenário / Código | Tipo | Motivo | Comportamento Esperado |
| --- | --- | --- | --- |
| Acesso/mutação pós-dispose | `StateError` | Uso de `Signal`, `Computed`, `Resource`, `StreamResource` ou `Command` após `dispose()` | Lança `StateError` explícito |
| Dependência ausente no escopo | `StateError` | `readKortex<T>()` ou `watchKortex<T>()` sem `KortexProvider<T>` ancestral | Lança `StateError` indicando tipo `T` ausente |
| Dependência circular no escopo | `StateError` | Ciclo entre providers irmãos durante resolução/criação | Lança `StateError` indicando a cadeia do ciclo |
| Falha em operação assíncrona | `KortexAsyncError<T>` | Exceção no `loader` de `KortexResource`, no `Stream` de `KortexStreamResource` ou na `action` de `KortexCommand` | Publica `KortexAsyncError(error, stackTrace)` se ativo |
| Resposta tardia / superada | Descarte silencioso | `loader`, `Stream` ou `action` resolve após `dispose()` (ou novo `refresh()` / `restart()`) | Ignora resultado/erro sem alterar `state` |
| Disparo concorrente em `Command` | Ignorado | `execute()` chamado com `isExecuting == true` | Retorna `null` sem iniciar nova execução |

---

## 7. Requisitos Não-Funcionais (NFRs Mensuráveis)

- **NFR-01 (Dependências)**: 0 dependências externas em `pubspec.yaml` (apenas `flutter: sdk: flutter`).
- **NFR-02 (Conformidade Estática)**: 0 erros e 0 warnings em `flutter analyze` sob `flutter_lints`.
- **NFR-03 (Pureza de Camada)**: 0 imports de `package:flutter/` ou referências a `BuildContext` em `lib/src/reactive/`.
- **NFR-04 (Segurança de Ciclo de Vida)**: 0 chamadas a `setState` ou `listener` com `mounted == false` e 0 atualizações após `dispose()`.
- **NFR-05 (Convenção `I-`)**: 100% das interfaces, classes abstratas e `sealed` com prefixo `I`.

---

## 8. Contratos por Operação (DbC leve)

- **`KortexSignal.value` (get/set)**:
  - *Pré-condição*: `!isDisposed`.
  - *Pós-condição (set)*: se `!equals(_value, newValue)`, atualiza `_value` e agenda/dispara notificação respeitando `kortexBatch`.
- **`KortexComputed.value` (get)**:
  - *Pré-condição*: `!isDisposed`.
  - *Pós-condição*: recomputa sob `KortexTracker` apenas se `_isDirty || !_hasValue`.
- **`KortexEffect` (execução)**:
  - *Pré-condição*: `!isDisposed`.
  - *Pós-condição*: executa `onCleanup` anterior e cancela eventual timer de `debounce` antes de reexecutar; limpa todas as assinaturas e timers no `dispose()`.
- **`KortexStreamResource.dispose()`**:
  - *Pós-condição*: cancela a `StreamSubscription` ativa e descarta o sinal interno de estado.
- **`KortexCommand.execute(param)`**:
  - *Pré-condição*: `!isDisposed`.
  - *Pós-condição*: se `!isExecuting`, executa `action(param)` com trava de reentrância e garante `isExecuting = false` ao final (se não descartado).
- **`KortexScope.dispose()`**:
  - *Pós-condição*: descarta em ordem LIFO todas as instâncias materializadas sob posse do escopo (callbacks explícitos ou `IKortexDisposable`), preservando instâncias de `KortexProvider.value`.

# Kortex — Product Requirements Document (PRD)

> **Status**: `Aprovado`  
> **Versão**: `0.1.0` | **Data**: `2026-11-19`  
> **Product Owner**: Denerson Nobre

---

## 1. Visão Geral & Proposta de Valor

Kortex é um pacote Dart/Flutter minimalista e de zero dependências externas (`sdk: flutter`) que fornece reatividade granular por sinais (`KortexSignal`, `IKortexReadonlySignal`, `KortexComputed`, `KortexEffect`, `KortexResource`, `KortexCommand`), escopo explícito de dependências na árvore de widgets (`KortexScope`) com ciclo de vida determinístico (`dispose`), contratos para UI prioritariamente `StatelessWidget` (`IKortexController`, `IKortexPage`, `IKortexDisposable`) e construção reativa de UI (`KortexWatch`, `KortexSelector`, `KortexListener`, `KortexResourceBuilder`).

### 1.1 Declaração do Problema (Problem Statement)

- **Cenário Atual**: Aplicações Flutter frequentemente oscilam entre frameworks monolíticos "tudo-em-um" (como GetX, com Service Locator global, navegação sem `BuildContext` e estado mutável exposto sem fronteira) ou pilhas fragmentadas de múltiplos pacotes acoplados.
- **Pontos de Fricção (Pain Points)**:
  - *Fricção 1*: Conflitos de versão no `pubspec.yaml` e lock-in de pacotes externos de terceiros.
  - *Fricção 2*: Service Locator global estático (`put`/`find` sem contexto) e ciclo de vida "mágico" dificultam testes isolados e favorecem vazamento de estado entre telas e fluxos.
  - *Fricção 3*: Ausência de primitivas completas para o dia a dia (efeitos colaterais seguros, mutações assíncronas com trava de duplo clique, agrupamento transacional de atualizações, encapsulamento somente-leitura e páginas `StatelessWidget` conectadas a controllers escopados) leva a boilerplate ou anti-patterns durante `build`.

### 1.2 Proposta de Valor & Diferencial Competitivo

- **Para**: Desenvolvedores Flutter e equipes construindo aplicações modulares / por feature.
- **Que buscam**: Reatividade granular completa, encapsulamento de estado, UI prioritariamente `StatelessWidget`, escopo explícito na árvore de widgets e segurança assíncrona — sem cair nas armadilhas do GetX.
- **O Kortex é**: Uma biblioteca Dart/Flutter minimalista de reatividade por sinais e escopo de dependências vinculado à árvore de widgets.
- **Que entrega**:
  - **Zero dependências de terceiros**: elimina conflitos de versão no `pubspec.yaml` e lock-in de pacotes externos.
  - **Anti-GetX por construção**: zero Service Locator global, zero `BuildContext` implícito, zero classe base mágica de controller e zero acoplamento a roteador/HTTP/storage.
  - **UI prioritariamente `StatelessWidget`**: `IKortexPage<TController>` + `KortexWatch` / `KortexSelector` / `KortexListener` eliminam a necessidade de `StatefulWidget` na maior parte das telas.
  - **Escopo explícito e testável**: dependências (controllers, serviços, repositories e datasources) resolvidas na árvore via `BuildContext` com `overrides` fáceis para testes de widget e `dispose` determinístico.
  - **Encapsulamento real**: `IKortexReadonlySignal<T>` permite que controllers exponham leitura reativa sem expor mutação para a UI.

---

## 2. Personas & Jornadas de Usuário

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        MAPA DE PERSONAS PRINCIPAIS                     │
├──────────────────────────────┬─────────────────────────────────────────┤
│  Dev Flutter Minimalista     │  Arquiteto / Dev de Feature Modular     │
│  Papel: Consumidor do Pacote │  Papel: Estruturador de Fluxos/Telas    │
│  Foco: StatelessWidget, Zero │  Foco: Encapsulamento, Lifecycle        │
│        Deps e Zero Mágica    │        Determinístico e Testes Isolados │
└──────────────────────────────┴─────────────────────────────────────────┘
```

### 2.1 Persona 1: Desenvolvedor Flutter Minimalista

- **Perfil Demográfico / Contexto**: Desenvolvedor Dart/Flutter que evita frameworks monolíticos e quer controle explícito sobre estado, efeitos e UI baseada em `StatelessWidget`.
- **Dores Principais**: Rebuilds desnecessários, mutabilidade vazada para a view, callbacks de erro/navegação disparados durante `build` e duplo clique em botões assíncronos.
- **Jornada de Sucesso (Happy Path)**:
  1. Declara apenas `kortex` (dependência exclusiva de `sdk: flutter`) no `pubspec.yaml`.
  2. Modela estado privado com `KortexSignal` dentro de um `IKortexController`, expõe `IKortexReadonlySignal`/`KortexComputed`, usa `KortexResource` para leitura e `KortexCommand` para mutações.
  3. Constrói a tela estendendo `IKortexPage<MeuController>` (`StatelessWidget`) com `KortexWatch`, `KortexSelector`, `KortexListener` e `KortexResourceBuilder`.

### 2.2 Persona 2: Desenvolvedor de Aplicação Modular / Por Feature

- **Perfil Demográfico / Contexto**: Engenheiro construindo fluxos/rotas independentes com repositories, datasources, serviços e controllers por subárvore.
- **Dores Principais**: Serviços pesados instanciados antes da hora, dependência entre providers do mesmo escopo, vazamento de instâncias após saída de rota e setup verboso em testes.
- **Jornada de Sucesso (Happy Path)**:
  1. Registra datasources, repositories, serviços e controllers em `KortexScope` via `KortexProvider<T>` (inclusive `lazy: true` ou `.value`), com suporte a `overrides` em testes.
  2. Consome instâncias na subárvore com `context.readKortex<T>()` e `context.watchKortex<T>()`.
  3. Ao desmontar a subárvore, o `KortexScope` executa o `dispose` determinístico de todas as instâncias sob sua posse (callback explícito ou `IKortexDisposable`).

---

## 3. Escopo do MVP (`v0.1.0`) & Requisitos Funcionais (RF)

### 3.1 Escopo Incluído

- **Núcleo Reativo e Contratos em Dart puro (`reactive/`)**:
  - Primitivas de estado e derivação: `KortexSignal<T>`, `IKortexReadonlySignal<T>`, `KortexComputed<T>`.
  - Efeitos, transações e leitura não rastreada: `KortexEffect` (com `debounce` opcional via `dart:async`), `kortexBatch`, `kortexUntracked` (e `peek()`).
  - Assincronia para leitura e escrita: `KortexResource<T>` (com preservação de `previousValue` durante `refresh()`), `KortexStreamResource<T>` (ponte para `Stream<T>` com cancelamento automático), `IKortexAsyncState<T>` e `KortexCommand<TParam, TResult>`.
  - Ciclo de vida e controllers: `IKortexDisposable`, `KortexDisposeBag` e `IKortexController` (inicialização no construtor e descarte via `disposeBag`/`onDispose`).
- **Escopo na Árvore de Widgets (`scope/`)**:
  - `KortexProvider<T>` (suporte a `lazy`, `.value` e auto-dispose opcional via contrato explícito `IKortexDisposable`).
  - `KortexScope` (com resolução entre irmãos no mesmo escopo, detecção de ciclos, `overrides` para testes e `KortexScope.capture` para modais/dialogs em `Overlay`).
  - Extensões em `BuildContext`: `readKortex<T>()` e `watchKortex<T>()`.
- **Widgets de UI (`StatelessWidget`-first) e Ponte com SDK Flutter (`widgets/`)**:
  - `IKortexPage<TController extends IKortexController>` (`StatelessWidget` com resolução explícita via `BuildContext`).
  - `KortexWatch` (com `child` estático opcional), `KortexSelector<T>`, `KortexListener` e `KortexResourceBuilder<T>`.
  - Pontes bidirecionais com `Listenable` do Flutter e `Stream`: `toKortexSignal()` em `ValueListenable<T>` (`TextEditingController`, `ValueNotifier`), `toKortexSignalWith<T>(read)` em `Listenable` (`ChangeNotifier`, `ScrollController`), `toListenable()` e `toStream()` em `IKortexReadonlySignal<T>` (para `refreshListenable` do `go_router` e consumidores de `Stream<T>`), sem violar a pureza de `reactive/`.
- **Ergonomia por Typedefs e Extensions**:
  - `typedef`s semânticos para assinaturas de callbacks (`KortexEquals<T>`, `KortexUpdater<T>`, `KortexCreate<T>`, `KortexWatchBuilder`, etc.) e `extension`s fluentes (`addTo(bag)`, `toggle()`, `increment()`, `decrement()`, `toKortexSignal()`, `toListenable()`) mantendo uma única forma idiomática (`.value` e `switch` nativo do Dart 3) sem mágica global.
- **Qualidade & Exemplo**:
  - Testes unitários e de widget (`flutter_test`) cobrindo reatividade, transações, efeitos, concorrência, escopo, ciclos, `dispose`, `IKortexController`, `IKortexPage` e UI.

### 3.2 Requisitos Funcionais (RF)

- **RF-01 (Sinal Mutável e Visão Somente-Leitura)**: Permitir leitura, escrita, atualização condicional (`update`), igualdade customizada (`equals`) e leitura sem assinatura (`peek()`); expor visão `IKortexReadonlySignal<T>` para encapsulamento; notificar observadores apenas quando houver mudança; bloquear acesso/mutação após `dispose()`.
- **RF-02 (Valor Computado)**: Derivar valores de forma preguiçosa (`lazy`) com cache, implementando `IKortexReadonlySignal<T>`; recalcular apenas quando dependências mudarem e liberar assinaturas no `dispose()`.
- **RF-03 (Efeito, Lote Transacional e Leitura Não Rastreada)**: Permitir execução de efeitos colaterais em Dart puro via `KortexEffect` com callback de limpeza (`onCleanup`), `debounce` opcional e `dispose()` explícito; agrupar múltiplas mutações sem glitches via `kortexBatch`; permitir leituras sem registro de dependência via `kortexUntracked`.
- **RF-04 (Recurso, Stream e Comando Assíncronos)**: Gerenciar fluxos de leitura em `KortexResource<T>` (`loading` com `previousValue` opcional durante `refresh()`, `data`, `error`) descartando respostas superadas por `refresh()` ou `dispose()`; suportar streams em `KortexStreamResource<T>` com cancelamento automático de `StreamSubscription` no `dispose()`; gerenciar ações/mutações em `KortexCommand<TParam, TResult>` com `isExecuting`, trava contra reentrância/duplo disparo e estado reativo seguro pós-`dispose`.
- **RF-05 (Descarte Composto e Controllers)**: Fornecer `IKortexDisposable`, `KortexDisposeBag` e `IKortexController` (sem `onInit` mágico — inicialização no construtor) para agrupar e descartar múltiplas primitivas reativas de forma determinística. Repositories, datasources e serviços do app são registrados diretamente no `KortexScope` e implementam `IKortexDisposable` apenas quando precisam liberar recursos.
- **RF-06 (Escopo, Lazy, Irmãos, Capture e Overrides)**: Instanciar dependências registradas no `KortexScope` (eager ou `lazy`), suportar `KortexProvider.value` sem posse de ciclo de vida, resolver dependências entre providers do mesmo escopo com detecção explícita de ciclo, capturar escopos ancestrais para `Overlay`/`showDialog`/`showModalBottomSheet` via `KortexScope.capture`, suportar `overrides` para testes e executar `dispose` ao desmontar ou atualizar o escopo.
- **RF-07 (UI Stateless-First, Seleção, Efeitos e Ponte SDK)**: Permitir páginas `StatelessWidget` via `IKortexPage<TController>` usando `BuildContext`; reconstruir apenas o `KortexWatch` (preservando `child` estático) ou `KortexSelector<T>` afetado; executar efeitos imperativos com `BuildContext` real fora da fase de `build` via `KortexListener` (inclusive para navegação); renderizar `IKortexAsyncState<T>` exaustivamente via `KortexResourceBuilder<T>`; e fornecer pontes `toKortexSignal()` / `toListenable()` para integração com `ValueListenable<T>` e `refreshListenable` de roteadores como `go_router`.

---

## 4. Requisitos Não Funcionais (RNF) & Restrições Anti-GetX

- **RNF-01 (Zero Dependências Externas)**: `pubspec.yaml` contém apenas `flutter` (`sdk: flutter`) em `dependencies`.
- **RNF-02 (Pureza da Camada Reativa)**: `lib/src/reactive/` não importa `package:flutter/widgets.dart` nem depende de `BuildContext`.
- **RNF-03 (Zero Estado Global / Zero Mágica)**: Nenhuma API resolve dependências sem `BuildContext` ou árvore de widgets; nenhuma classe usa reflexão/duck-typing para ciclo de vida.
- **RNF-04 (Segurança de Ciclo de Vida)**: Nenhuma notificação dispara em nó ou widget já descartado (`disposed` / `!mounted`), e todo efeito fora da UI retorna handle descartável explícito.
- **RNF-05 (Convenção Nominal do Ecossistema)**: Toda interface, classe abstrata ou `sealed` inicia obrigatoriamente com o prefixo `I` (`IKortex*`), classes concretas iniciam com `Kortex*` e funções utilitárias com `kortex*`.

---

## 5. Limites do Produto & Fora de Escopo (Explicit Non-Goals)

Para assegurar previsibilidade, minimalismo e proteção contra o inchaço do GetX, os seguintes itens estão **expressamente fora do escopo**:

1. **Service Locator global estático** (`Kortex.put` / `Kortex.find` sem `BuildContext`/escopo).
2. **EventBus global** (`emit` / `on`).
3. **Roteador próprio ou abstração de navegação** (funciona com `Navigator`, `go_router`, etc.).
4. **Helpers sem `BuildContext`** para diálogos, snackbars, temas ou mídia (`Get.dialog`, `Get.snackbar`, `Get.theme`).
5. **Cliente HTTP, persistência local, serialização JSON, i18n, logger global estático ou abstrações cerimoniais de `Repository`/`DataSource`**.
6. **Code generation (`build_runner`) ou CLI (`kortex_cli`)**.

---

## 6. Critérios de Sucesso & Métricas de Aceite

| Métrica / Indicador | Linha de Base | Meta do Produto (Target) |
| --- | --- | --- |
| **Conformidade Estática (`flutter analyze`)** | N/A (novo pacote) | **0 warnings / 0 erros sob `flutter_lints`** |
| **Dependências Externas (`dependencies`)** | Pacotes de terceiros | **0 dependências externas (apenas `sdk: flutter`)** |
| **Cobertura de Cenários Críticos em Testes** | 0% | **100% dos cenários críticos cobertos**: `Signal` (`equals`, `peek`), `Computed`, `Effect` (`onCleanup`, `debounce`), `Batch`, `Untracked`, `Resource` (`previousValue`, race condition/erro), `StreamResource` (emissão/cancelamento), `Command` (reentrância), `DisposeBag`, `IKortexController`, `Scope` (aninhado, irmãos, ciclo, `lazy`, `.value`, `capture`, `overrides`, `dispose`), `IKortexPage`, `Watch` (`child`), `Selector`, `Listener`, `ResourceBuilder` e pontes `toKortexSignal()` / `toListenable()` |
| **Exemplo Funcional** | N/A | **App de exemplo com `StatelessWidget` (`IKortexPage`), `IKortexController`, repository/datasource registrados em `KortexScope`, `KortexCommand`, `KortexResource` e `KortexListener` sem dependências externas** |

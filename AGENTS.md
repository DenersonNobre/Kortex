# AGENTS.md — Kortex

> Fonte única de contexto do projeto. Proibido criar `CLAUDE.md`, `GEMINI.md` ou shims em `.cursor/rules/`.

## 1. Mandato & Não-Negociáveis

- **Antes de qualquer trabalho**: leia `CHECKPOINT.md` e `docs/architecture/SPEC.md` (e `docs/plan/state/UC-CURRENT.md` quando existir).
- **Zero dependências externas**: `packages/kortex_state/pubspec.yaml` aceita exclusivamente `flutter` (`sdk: flutter`) em `dependencies`; nunca adicione pacotes de terceiros.
- **Pureza da camada reativa (`INV-05`)**: `packages/kortex_state/lib/src/reactive/` é Dart puro; nunca importe `package:flutter/widgets.dart` nem use `BuildContext` nessa pasta.
- **Escopo explícito (`INV-06`)**: nunca crie Service Locator global (`put`/`find`), EventBus global, roteador próprio, helpers sem `BuildContext` ou `onInit` mágico.
- **Bloqueio pós-dispose e respostas tardias (`INV-01`/`INV-02`)**: lance `StateError` em acesso pós-`dispose()`; descarte silenciosamente resultados assíncronos superados por `refresh()`/`dispose()`.

## 2. Comandos Essenciais

- **Dependências**: `flutter pub get` — resolve o SDK Flutter sem dependências externas.
- **Análise estática**: `flutter analyze` — deve encerrar com `No issues found!` (zero warnings sob `flutter_lints`).
- **Testes (suíte completa)**: `flutter test` — executa testes unitários e de widget em `test/` (exit 0 = verde).
- **Teste de arquivo único**: `flutter test test/kortex_test.dart` (em `packages/kortex_state/`) — validação rápida de fatia.

## 3. Onde Está O Que

- **Produto**: `docs/product/PRD.md` (escopo, requisitos `RF-01`..`RF-07`, `RNF-01`..`RNF-05`, não-objetivos).
- **Verdade do domínio**: `docs/architecture/SPEC.md` (regras `RN-01`..`RN-06`, invariantes `INV-01`..`INV-08`, contratos).
- **Continuidade e diário**: `CHECKPOINT.md` (≤ 60 linhas) e `LEARNINGS.md`.
- **Layout de código**: monorepo com workspace na raiz (`pubspec.yaml`) e pacote principal em `packages/kortex_state/` (`lib/kortex.dart`, `lib/src/{reactive,scope,widgets}/`, `test/`, `example/`).

## 4. Convenções & Testes

- **Idioma**: identificadores e APIs em inglês com prefixo `Kortex` (`kortex` em helpers); documentação e mensagens de commit em pt-BR.
- **Regra `I-` (`INV-08` / `flutter.md`)**: toda interface, classe abstrata ou `sealed` pública inicia obrigatoriamente com `I` (`IKortexObserver`, `IKortexReactiveNode`, `IKortexDisposable`, `IKortexReadonlySignal`, `IKortexAsyncState`, `IKortexScopeReader`, `IKortexController`, `IKortexPage`); classes concretas usam `Kortex*`.
- **Sintaxe única**: leitura de sinais via `.value` / `.peek()` (sem `call()`); pattern matching em `IKortexAsyncState<T>` via `switch` nativo do Dart 3 (sem `when`/`maybeWhen`).
- **Testes**: `flutter_test` em `test/` com TDD Red-Before-Green cobrindo reatividade pura, concorrência assíncrona, resolução/ciclos/descarte em `KortexScope` e widgets `StatelessWidget`-first.

## 5. Workflow

- **Commits**: Conventional Commits atômicos, testes e docs (`CHANGELOG.md`, `LEARNINGS.md`, `CHECKPOINT.md`) no mesmo commit; **push somente com pedido explícito do usuário**.
- **Gate Zero**: não criar código em `lib/src/` antes da aprovação do quarteto canônico (`SPEC.md`, `DESIGN.md`, `docs/plan/README.md`, `docs/plan/epics/epic-00-fundacao.md`).
- **Evidência**: nenhuma conclusão sem a cadeia `[Leitura] → [Verificação] → [Confirmação]`.

## 6. Tópicos & Skills Carregáveis (sob demanda)

| Quando… | Carregar |
| --- | --- |
| Trabalhar com Flutter/Dart, convenção `I-` ou widgets | `~/.agents/rules/topics/flutter.md` |
| Editar arquivos `.md` | `~/.agents/rules/topics/markdown.md` |
| Operar commits/claims concorrentes | `~/.agents/rules/topics/git-multiagent.md` |

## 7. Gotchas do Projeto

- **`KortexListener<T>`**: separar `watch` (leitura pura em `initState` para descobrir dependências) de `listener` (efeito fora do `build`), evitando disparo indevido com `fireImmediately: false`.
- **Conflito de extensão `Listenable` vs `ValueListenable<T>`**: usar `ValueListenable<T>.toKortexSignal()` e `Listenable.toKortexSignalWith<T>(read)` para evitar ambiguidade de resolução estática no Dart.
- **`KortexScope` em rebuilds do pai**: preservar instâncias durante o `State` (não resetar por comparação de lista de providers); usar `Key` quando reinicialização explícita for desejada.

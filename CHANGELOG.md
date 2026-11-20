# Changelog — Kortex

Mudanças notáveis deste repositório. Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento: [SemVer](https://semver.org/lang/pt-BR/). Categorias: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## Como este arquivo é mantido

- **Quem escreve**: quem faz a mudança. Alteração observável entra em `[Não publicado]` no mesmo commit da mudança.
- **Quando vira release**: promovido para uma versão datada na tag `vX.Y.Z` correspondente.
- **Não confundir com `LEARNINGS.md`**: aquele é o diário técnico; este é a linha de release.

## [Não publicado]

### Added

- `IKortexDisposable`, `KortexDisposeBag` e `IKortexController` em `lib/src/reactive/` com descarte LIFO idempotente e `onDispose` antes do bag (`UC-01.01`).
- `KortexTracker` (fila deduplicada, `kortexBatch`, `kortexUntracked`), `IKortexReadonlySignal` e `KortexSignal` com `equals` configurável e bloqueio pós-`dispose` (`UC-01.02`).
- Barrel `lib/src/reactive/reactive.dart` reexportando a camada reativa em um único import.
- `KortexComputed` (lazy, cache, invalidação em cascata, `equals` na jusante) e `KortexEffect` (`onCleanup`, `debounce`, guarda anti-reentrância) (`UC-01.03`, `EPIC01` concluída).
- `IKortexAsyncState` selada e `KortexResource` com `previousValue` e descarte por geração monotônica (`UC-02.01`).
- `KortexStreamResource` (cancelamento + `restart` com geração), `toStream()` e `KortexCommand` (trava de reentrância) (`UC-02.02`, `EPIC02` concluída).
- `KortexProvider`, `KortexScope` (irmãos, ciclo com cadeia, `lazy`, LIFO, preservação em rebuild) e `readKortex`/`watchKortex` (`UC-03.01`).

- Esqueleto inicial do pacote Flutter `kortex` (`pubspec.yaml`, `analysis_options.yaml`, `lib/kortex.dart`, `test/kortex_test.dart`).
- Documentação de produto e arquitetura da `v0.1.0` em `docs/product/PRD.md` e `docs/architecture/SPEC.md` (reatividade em Dart puro, `KortexScope`, `IKortexPage` `StatelessWidget`-first, pontes `Stream`/`ValueListenable`/`Listenable`, guardrails Anti-GetX e convenção `I-`).

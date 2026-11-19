# Kortex

Pacote Dart/Flutter minimalista e com **zero dependências externas** (`sdk: flutter`) para reatividade granular por sinais, escopo explícito de dependências na árvore de widgets (`KortexScope`) e UI construída prioritariamente com `StatelessWidget` (`IKortexPage`).

> **Estado atual**: Especificação de produto e domínio consolidada (`v0.1.0` em fase de documentação/planejamento; implementação ainda não iniciada).

---

## Por que Kortex?

- **Zero dependências de terceiros**: apenas `flutter` (`sdk: flutter`) em `dependencies` no `pubspec.yaml`.
- **Anti-GetX por construção**: sem Service Locator global (`put`/`find`), sem `EventBus` global, sem roteador próprio, sem helpers sem `BuildContext` e sem `onInit` mágico.
- **Encapsulamento real**: `IKortexReadonlySignal<T>` expõe leitura reativa para a UI mantendo `KortexSignal<T>` privado no controller.
- **UI `StatelessWidget`-first**: `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener<T>` e `KortexResourceBuilder<T>` encapsulam os `StatefulWidget`s internamente.
- **Ciclo de vida determinístico**: instâncias registradas em `KortexScope` são descartadas em ordem reversa (`dispose`) ao desmontar a subárvore.

---

## Arquitetura em Camadas

- **`lib/src/reactive/` (Dart puro)**: `KortexSignal`, `IKortexReadonlySignal`, `KortexComputed`, `KortexEffect`, `kortexBatch`, `kortexUntracked`, `KortexResource`, `KortexStreamResource`, `KortexCommand`, `IKortexDisposable`, `KortexDisposeBag`, `IKortexController` — sem qualquer import de `package:flutter/widgets.dart`.
- **`lib/src/scope/` (Flutter SDK)**: `KortexProvider<T>` (`eager`, `lazy`, `.value`), `KortexScope` (resolução hierárquica e entre irmãos com detecção de ciclo, `overrides` para testes e `KortexScope.capture` para modais/dialogs em `Overlay`) e extensões `readKortex<T>()` / `watchKortex<T>()` em `BuildContext`.
- **`lib/src/widgets/` (Flutter SDK)**: `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener<T>`, `KortexResourceBuilder<T>` e pontes com `Listenable` / `ValueListenable<T>` (`toKortexSignal()`, `toKortexSignalWith()`, `toListenable()`).

---

## Documentação Canônica

- **Requisitos de Produto**: [docs/product/PRD.md](docs/product/PRD.md)
- **Especificação Técnica de Domínio**: [docs/architecture/SPEC.md](docs/architecture/SPEC.md)
- **Histórico de Mudanças**: [CHANGELOG.md](CHANGELOG.md)

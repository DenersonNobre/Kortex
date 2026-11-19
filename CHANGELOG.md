# Changelog — Kortex

Mudanças notáveis deste repositório. Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento: [SemVer](https://semver.org/lang/pt-BR/). Categorias: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## Como este arquivo é mantido

- **Quem escreve**: quem faz a mudança. Alteração observável entra em `[Não publicado]` no mesmo commit da mudança.
- **Quando vira release**: promovido para uma versão datada na tag `vX.Y.Z` correspondente.
- **Não confundir com `LEARNINGS.md`**: aquele é o diário técnico; este é a linha de release.

## [Não publicado]

### Added

- Esqueleto inicial do pacote Flutter `kortex` (`pubspec.yaml`, `analysis_options.yaml`, `lib/kortex.dart`, `test/kortex_test.dart`).
- Documentação de produto e arquitetura da `v0.1.0` em `docs/product/PRD.md` e `docs/architecture/SPEC.md` (reatividade em Dart puro, `KortexScope`, `IKortexPage` `StatelessWidget`-first, pontes `Stream`/`ValueListenable`/`Listenable`, guardrails Anti-GetX e convenção `I-`).

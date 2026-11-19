# CHECKPOINT — kortex (v0.1.0)

> Ponteiro, nunca espelho (protocolo: `agents/rules/workflow_rules.md` §Continuidade).
> Backlog/DAG: `docs/plan/README.md` · fatia corrente: `docs/plan/state/UC-CURRENT.md` ·
> PRD: `docs/product/PRD.md` · SPEC: `docs/architecture/SPEC.md` · DESIGN: `docs/architecture/DESIGN.md` ·
> diário: `LEARNINGS.md`.
> **Budget: ≤60 linhas** — acima disso é espelho disfarçado de ponteiro; recorte.

## Contexto

Pacote Flutter/Dart `kortex` (`v0.1.0`; `EPIC00` concluído, iniciando `EPIC01` sob TDD).

## Estado real (verificado em 2026-11-19)

- Branch `main` com `EPIC00` (`UC-00.01`) concluído: esqueleto do pacote, `.gitattributes`, `AGENTS.md`, `PRD.md`, `SPEC.md`, `DESIGN.md`, `docs/plan/`.
- Baselines medidos: `flutter analyze` (`No issues found!`) e `flutter test` (`All tests passed!`).

## Próximo passo acionável

1. Implementar `UC-01.01` (`IKortexDisposable`, `KortexDisposeBag`, `IKortexController`) sob TDD Red-Before-Green.
2. Seguir a DAG (`EPIC01` → `EPIC02` / `EPIC03` → `EPIC04`).

## Travas vivas

- Nenhuma trava bloqueante; push somente com pedido explícito do usuário.

## Regras (não apagar ao instanciar)

1. Aponta para a fonte viva, nunca duplica status/métricas/backlog (cópia envelhece no próximo commit).
2. Sem histórico — histórico é `git log`. Atualizado no commit que fecha a unidade de trabalho.
3. Ordem de leitura ao retomar: `CHECKPOINT.md` → `uc-current.md` → código.
4. Ciclo pontual usa `checkpoint.md` minúsculo (scratch, eliminado ao fechar); continuidade usa este arquivo.

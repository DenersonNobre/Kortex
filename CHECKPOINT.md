# CHECKPOINT — kortex (monorepo)

> Ponteiro, nunca espelho (protocolo: `agents/rules/workflow_rules.md` §Continuidade).
> Backlog/DAG: `docs/plan/README.md` · fatia corrente: `docs/plan/state/UC-CURRENT.md` ·
> PRD: `docs/product/PRD.md` · SPEC: `docs/architecture/SPEC.md` · DESIGN: `docs/architecture/DESIGN.md` ·
> diário: `LEARNINGS.md`.
> **Budget: ≤60 linhas** — acima disso é espelho disfarçado de ponteiro; recorte.

## Contexto

Monorepo Dart Pub Workspace (`pubspec.yaml` raiz) com `packages/kortex_state` (`kortex 0.2.3`), `packages/kortex_lint` (`0.1.2`), `packages/kortex_persist` (`0.1.0`), `packages/kortex_lib` (`publish_to: none`, migrado da `dnolib` sem `synapx` e podado) e `poc/`.

## Estado real (verificado em 2026-11-23)

- Publicados no `pub.dev`: `kortex 0.2.3`, `kortex_lint 0.1.2` e `kortex_persist 0.1.0` (todos com `topics:` e `example/`).
- `packages/kortex_lib` validado (`302` testes) e `poc/` validado (`105` testes).

## Próximo passo acionável

1. Próximo ciclo sob demanda (integrar `kortex`/`kortex_lint`/`kortex_lib` no `service_track` ou avançar no roadmap `v0.2.x`).

## Travas vivas

- Nenhuma trava bloqueante; `gitea.lan` retornou `502` em push anterior (`origin` está sincronizado).

## Regras (não apagar ao instanciar)

1. Aponta para a fonte viva, nunca duplica status/métricas/backlog (cópia envelhece no próximo commit).
2. Sem histórico — histórico é `git log`. Atualizado no commit que fecha a unidade de trabalho.
3. Ordem de leitura ao retomar: `CHECKPOINT.md` → `docs/plan/state/UC-CURRENT.md` → código.
4. Ciclo pontual usa `checkpoint.md` minúsculo (scratch, eliminado ao fechar); continuidade usa este arquivo.

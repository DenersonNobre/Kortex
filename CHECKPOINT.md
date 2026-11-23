# CHECKPOINT — kortex (monorepo)

> Ponteiro, nunca espelho (protocolo: `agents/rules/workflow_rules.md` §Continuidade).
> Backlog/DAG: `docs/plan/README.md` · fatia corrente: `docs/plan/state/UC-CURRENT.md` ·
> PRD: `docs/product/PRD.md` · SPEC: `docs/architecture/SPEC.md` · DESIGN: `docs/architecture/DESIGN.md` ·
> diário: `LEARNINGS.md`.
> **Budget: ≤60 linhas** — acima disso é espelho disfarçado de ponteiro; recorte.

## Contexto

Monorepo Dart Pub Workspace (`pubspec.yaml` raiz) com 5 pacotes publicados no `pub.dev`: `kortex` (`0.2.3`), `kortex_lint` (`0.1.2`), `kortex_persist` (`0.1.0`), `kortex_lib` (`0.1.0`) e `kortex_forms` (`0.1.0`), além da `poc/`.

## Estado real (verificado em 2026-11-23)

- Todos os 5 pacotes publicados no `pub.dev` com `topics:` e `example/`.
- `kortex_lib` podado (sem `synapx`/reativos duplicados); `kortex_forms` mantém validações genéricas e `kortex_lib/brlib/` mantém especializações `pt-BR`.

## Próximo passo acionável

1. Validar o ecossistema Kortex em app real (`service_track`) ou avançar no roadmap `v0.2.x` de `kortex`.

## Travas vivas

- Nenhuma trava bloqueante.

## Regras (não apagar ao instanciar)

1. Aponta para a fonte viva, nunca duplica status/métricas/backlog (cópia envelhece no próximo commit).
2. Sem histórico — histórico é `git log`. Atualizado no commit que fecha a unidade de trabalho.
3. Ordem de leitura ao retomar: `CHECKPOINT.md` → `docs/plan/state/UC-CURRENT.md` → código.
4. Ciclo pontual usa `checkpoint.md` minúsculo (scratch, eliminado ao fechar); continuidade usa este arquivo.

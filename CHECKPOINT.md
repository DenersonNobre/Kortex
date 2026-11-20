# CHECKPOINT — kortex (v0.1.0)

> Ponteiro, nunca espelho (protocolo: `agents/rules/workflow_rules.md` §Continuidade).
> Backlog/DAG: `docs/plan/README.md` · fatia corrente: `docs/plan/state/UC-CURRENT.md` ·
> PRD: `docs/product/PRD.md` · SPEC: `docs/architecture/SPEC.md` · DESIGN: `docs/architecture/DESIGN.md` ·
> diário: `LEARNINGS.md`.
> **Budget: ≤60 linhas** — acima disso é espelho disfarçado de ponteiro; recorte.

## Contexto

Pacote Flutter/Dart `kortex` (`v0.1.0` tagueada; `EPIC00`–`EPIC04` concluídos).

## Estado real (verificado em 2026-11-20)

- Tag `v0.1.0` nos remotos Gitea e GitHub; CI dupla verde + prova negativa vermelha nos gates certos.
- Baselines medidos: `flutter analyze` (`No issues found!`) e `flutter test` (raiz 80/80, `example/` 1/1).

## Próximo passo acionável

1. Próximo ciclo sob demanda (nova `EPIC05+` ou manutenção via `support/vX.Y`).

## Travas vivas

- Nenhuma trava bloqueante; push somente com pedido explícito do usuário.

## Regras (não apagar ao instanciar)

1. Aponta para a fonte viva, nunca duplica status/métricas/backlog (cópia envelhece no próximo commit).
2. Sem histórico — histórico é `git log`. Atualizado no commit que fecha a unidade de trabalho.
3. Ordem de leitura ao retomar: `CHECKPOINT.md` → `uc-current.md` → código.
4. Ciclo pontual usa `checkpoint.md` minúsculo (scratch, eliminado ao fechar); continuidade usa este arquivo.

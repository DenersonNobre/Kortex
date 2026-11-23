# CHECKPOINT — kortex (v0.2.1)

> Ponteiro, nunca espelho (protocolo: `agents/rules/workflow_rules.md` §Continuidade).
> Backlog/DAG: `docs/plan/README.md` · fatia corrente: `docs/plan/state/UC-CURRENT.md` ·
> PRD: `docs/product/PRD.md` · SPEC: `docs/architecture/SPEC.md` · DESIGN: `docs/architecture/DESIGN.md` ·
> diário: `LEARNINGS.md`.
> **Budget: ≤60 linhas** — acima disso é espelho disfarçado de ponteiro; recorte.

## Contexto

Pacote Flutter/Dart `kortex` (`v0.2.1`; `EPIC00`–`EPIC09` + `KortexSet`, extensões `.kortex*` e aliases `Kortex`/`IKortex*` concluídos).

## Estado real (verificado em 2026-11-22)

- Estrutura monorepo (`Pub Workspace` na raiz + `packages/kortex_state/` + `packages/kortex_lib/` + `poc/`); `packages/kortex_state/lib/src/reactive/` completo com `KortexSignal` (`Kortex`), `IKortexReadonlySignal` (`IKortex`), `KortexList` (`IKortexList`), `KortexMap` (`IKortexMap`), `KortexSet` (`IKortexSet`) e extensões `.kortex`, `.kortexList`, `.kortexMap`, `.kortexSet`.
- `example/` atualizado para demonstrar todas as extensões e aliases; suíte raiz (`99` testes) e `example/` (`1` teste) verdes; `flutter pub publish --dry-run` com `0` warnings.

## Próximo passo acionável

1. Atualizar tag `v0.2.1`, executar `git push` (`origin` e `gitea`) e publicar `0.2.1` no `pub.dev` após confirmação explícita do usuário.

## Travas vivas

- Nenhuma trava bloqueante; push e publicação no `pub.dev` somente com pedido explícito do usuário.

## Regras (não apagar ao instanciar)

1. Aponta para a fonte viva, nunca duplica status/métricas/backlog (cópia envelhece no próximo commit).
2. Sem histórico — histórico é `git log`. Atualizado no commit que fecha a unidade de trabalho.
3. Ordem de leitura ao retomar: `CHECKPOINT.md` → `docs/plan/state/UC-CURRENT.md` → código.
4. Ciclo pontual usa `checkpoint.md` minúsculo (scratch, eliminado ao fechar); continuidade usa este arquivo.

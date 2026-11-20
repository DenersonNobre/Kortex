# Aprendizados — kortex

## 2026-11-19 — Barrel com ponto (`.reactive.dart`) não embarca no pub.dev

- **Sintoma:** `dart pub publish --dry-run` listou `kortex_*.dart` mas omitiu `.reactive.dart` do arquivo a publicar — o barrel funcionava local/git/CI e sumiria para consumidores do pacote.
- **Causa:** o empacotador do pub ignora dotfiles ao montar o archive; nada no `flutter analyze` ou `flutter test` acusa (15/15 verdes com o ponto).
- **Prevenção:** todo barrel novo passa por `dart pub publish --dry-run | Select-String <arquivo>` antes da release (prova incluída na `UC-04.04`); barrels publicados nunca usam prefixo `.`.


> Aprendizados específicos DESTE repositório (arquitetura, decisões, gotchas do projeto).
> Os transversais (qualquer projeto da mesma stack) sobem para `agents/rules/topics/<stack>.md`
> ou `agents/rules/global_learnings.md`; procedimento reutilizável vira Skill.
> Antes de deixar algo só aqui, teste: **"valeria se eu clonasse outro projeto de tecnologia
> idêntica?"** — sim → promove; não → fica. Nunca nomear projeto/cliente/tabela de outro
> contexto nos canônicos; aqui o contexto local é permitido e desejado.

## 2026-11-19 — Decisões de desenho pré-código na SPEC do Kortex

- **Sintoma:** Na revisão da `SPEC.md`, `KortexListener` com apenas `listener(context)` não conseguia descobrir sinais com `fireImmediately: false` sem disparar o efeito colateral no `initState`; além disso, `Listenable.toKortexSignal` colidia com `ValueListenable<T>.toKortexSignal()` por subtipagem em Dart.
- **Causa:** Misturar leitura reativa pura com efeito colateral na mesma closure impede descoberta segura de dependências na montagem; e extensões com o mesmo nome em `Listenable` e `ValueListenable<T>` geram ambiguidade estática no Dart.
- **Prevenção:** Manter `watch` separado de `listener` em `KortexListener<T>` (`docs/architecture/SPEC.md`) e usar nomes distintos (`ValueListenable<T>.toKortexSignal()` vs `Listenable.toKortexSignalWith<T>(read)`).

## Regras (não apagar ao instanciar)

1. Uma seção `## AAAA-MM-DD — <título>` por aprendizado, na mesma unidade de trabalho do fix.
2. Entrada sem sintoma medido é hipótese — marque como tal até ter evidência.
3. Ao remover código com entradas aqui, **generalizar o contexto** em vez de deletar
   (ex.: nome de app específico → "app Delphi com res em fresh clone").
4. Promoção: reutilizado em 2+ lugares → global; virou workflow → propor Skill.

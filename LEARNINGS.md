# Aprendizados — kortex

## 2026-11-19 — Barrel com ponto (`.reactive.dart`) não embarca no pub.dev

- **Sintoma:** `dart pub publish --dry-run` listou `kortex_*.dart` mas omitiu `.reactive.dart` do arquivo a publicar — o barrel funcionava local/git/CI e sumiria para consumidores do pacote.
- **Causa:** o empacotador do pub ignora dotfiles ao montar o archive; nada no `flutter analyze` ou `flutter test` acusa (15/15 verdes com o ponto).
- **Prevenção:** todo barrel novo passa por `dart pub publish --dry-run | Select-String <arquivo>` antes da release (prova incluída na `UC-04.04`); barrels publicados nunca usam prefixo `.`.

## 2026-11-19 — `KortexComputed` observado recomputa na hora; sem observador, só dirty
- **Sintoma:** `KortexComputed` avisava a jusante ao invalidar e só recomputava na leitura — derivado igual gerava notificação fantasma (teste `só notifica quando o derivado muda` falhou com 1 aviso onde esperava 0).
- **Causa:** notificação ansiosa antes da comparação por `equals`; a SPEC pede invalidação em cascata, mas o `equals` do construtor só faz sentido se gatear o aviso.
- **Fix:** sem observadores, só `_isDirty = true` (lazy); com observadores, `_recompute()` imediato e aviso só se o derivado mudou (`_storeIfChanged`). `KortexSelector` continua como filtro de rebuild na UI.


## 2026-11-19 — Ponte `toStream` estourou a pilha por assinar via tracker

- **Sintoma:** `toStream` com `runWithObserver` na anexação entrou em recursão infinita (`Stack Overflow`): `recordRead` chama `onRead` já na coleta, e a ponte lia+emitia de novo a cada aviso.
- **Causa:** `onRead` serve a dois momentos (coleta vs. notificação); `Computed`/`Effect` distinguem com `_isCollecting`, mas ponte folha não precisa de coleta.
- **Fix:** `_SignalStream._attach` assina direto via `node.addObserver(bridge)` — sem moldura de tracker; `onRead` passa a disparar só em mudança real, e o `cancel` remove o observador.

## 2026-11-20 — Testes async de widget: aguardar o `Future`, não o `pump`

- **Sintoma:** 3 testes quebraram sem defeito na lib: `complete()` + 1 `pump()` não garantia a continuação do `Future`; `showSnackBar` insere overlay que só constrói no frame seguinte; `TextEditingController.value` tipa `TextEditingValue`, não `String`.
- **Causa:** `pump()` não ordena microtasks do `Future` do recurso; overlay precisa de frame extra; tipo do `ValueListenable` é o do `value`, não o do texto.
- **Fix:** aguardar o `Future` do `refresh()` antes do `pump` (determinístico); `pump` duplo pós-`showSnackBar`; separar teste `ValueNotifier<String>` (fluxo) de `TextEditingController` (posse pós-dispose).

## 2026-11-20 — `KortexSelector` compõe `Computed` + `Watch` em vez de observar direto

- **Sintoma:** seletor precisava de coleta de deps, comparação por `equals`, agenda fora de fase e ciclo de vida — tudo já testado em `KortexComputed`/`KortexWatch`.
- **Causa:** reimplementar duplicaria a máquina de invalidação (e os seus bugs).
- **Fix:** `_KortexSelectorState` guarda só o `KortexComputed` (com o `equals` do widget) e o `build` retorna um `KortexWatch` interno que lê o derivado; `didUpdateWidget` recria o derivado e o rebuild do pai reassina o `Watch` interno.

## 2026-11-19 — `capture` precisa de token de tipo explícito

- **Sintoma:** `KortexScope.capture` montava providers `KortexProvider<dynamic>.value` cujo `type` resolvia `dynamic` — leitura no dialog lançava `StateError` de provider ausente mesmo com a instância coletada.
- **Causa:** o mapa do escopo é chaveado pelo `type` do provider; genérico apagado (`dynamic`) nunca casa com `T` na resolução, e o `as KortexProvider<T>` ainda quebraria o cast.
- **Fix:** `_CapturedProvider` privado carrega o `Type` coletado junto do valor; `_materialize` sem cast de provider (só `as T` no valor, com cheque real em runtime).

## 2026-11-19 — Um provider por `Type`: duplicata colide, não ordena

- **Sintoma:** teste de LIFO com dois providers do mesmo `Type` descartou só um (`['b']` em vez de `['b','a']`) — o mapa `_effective`/`_instances` usa `Type` como chave e o segundo registro sobrescreveu o primeiro.
- **Causa:** escopo resolve por tipo; dois providers do mesmo tipo na mesma lista é erro de configuração, não fila.
- **Fix:** teste usa tipos distintos (`TaggedDisposable<ServiceA>` vs `<ServiceB>`); semântica documentada — um `Type`, um provider por escopo (o `overrides` da `UC-03.02` substitui, nunca duplica).

> Aprendizados específicos DESTE repositório (arquitetura, decisões, gotchas do projeto). (arquitetura, decisões, gotchas do projeto).
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

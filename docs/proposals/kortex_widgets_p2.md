# Proposta: Segunda onda de widgets — `kortex_widgets` (P0/P1)

## 1. Objetivo & Posicionamento

Completar o `kortex_widgets` (hoje: primitivos migrados da `kortex_lib` + campos BR em `src/br/`) com os **padrões de tela inteira** que todo app repete e que o `pub.dev` não entrega bem: ou não existem, ou vêm com curva alta/acoplamento errado ao gerenciamento de estado.

- **Incluso**: organismos (páginas, listas, seletores, filtros, filtros de formulário) integrados a `kortex`/`kortex_forms`, genéricos e sem regra de negócio.
- **Não Incluso**: widgets de domínio; widgets BR (casa: `src/br/`, proposta `kortex_br.md`); dependências pesadas novas (cada widget deve nascer só com `flutter` + `kortex`/`kortex_forms`, ou viver em eixo separado/documentar a alternativa `pub.dev`).

---

## 2. Escopo em duas ondas

### Onda P0 — extrema necessidade, gap real no `pub.dev`

| Widget | Dor que resolve | Integração |
| --- | --- | --- |
| `AsyncListView` | Lista paginada + pull-to-refresh + scroll infinito + loading/empty/error/retry + skeleton | `KortexResource`/`KortexCommand` |
| `AsyncPage` | Scaffold `loading → error(retry) → content` com refresh | `KortexResource<T>` direto |
| `SearchableSelect` (single/multi, bottom sheet) | Seleção com busca e opções assíncronas (`dropdown_search` é pesado e alheio ao reativo) | devolve para `KortexField` |
| `FilterPanel` | Chips/filtros sincronizados com objeto de query (fonte crônica de bug layout+estado) | signals de filtro |
| `FormErrorSummary` + scroll-to-first-error | Form longo sem navegação de erros é UX quebrada | `KortexForm` |
| `DateRangeField` / `DateField` | Picker assíncrono + TextFormato + validação (curva alta clássica) | `KortexField<DateTime/DateTimeRange>` |
| `OfflineBanner` | Faixa sem-conexão/sincronizando com retry (stream + debounce, sem piscar) | stream de conectividade |
| `SkeletonList` | Esqueleto com N itens e layout estável (sem reflow — cf. bug do chip na POC) | — |

### Onda P1 — alto valor, segunda prioridade

`WizardStepper` (validação por etapa + resumo), `ResponsiveDataView` (tabela desktop / cards mobile, mesma fonte), `PermissionGate` (rationale → request → settings, com re-checagem no retorno), `UploadTile` (progresso + retry + cancel sobre o client `rest/`), `OtpPinField` (**avaliar `pinput` antes**: só criar se a integração `KortexField` justificar).

### Melhorias nos existentes (antes ou junto da P0)

- `SearchPanel`: variante com **sugestões assíncronas** (hoje só texto + debounce).
- `StateViews`/`SnapshotBuild`: retry ligado a `KortexCommand` + predicado de "vazio" customizável.
- `BusyOverlay`: escopo por operação (dois comandos simultâneos sem se anularem).
- `modals`: sheet padrão com drag handle + safe area + **keyboard avoidance**.
- Todos: pente de **acessibilidade** (`semanticsLabel`, contraste, alvo 48dp) e teste geométrico (como o da POC), não só "compila".

---

## 3. Governança & Gate de Entrada

1. **Pré-requisito**: `PresenterScope` vs `KortexScope` decidido (hoje há dois mecanismos de escopo paralelos — segundo viola o espírito de INV-06; nenhum widget novo pode depender do `PresenterScope` até a decisão).
2. **Regra por widget**: genérico, testado (widget test + bordas geométricas onde houver layout), documentado ("quando usar / quando NÃO usar"). Nada de regra de negócio; nada de dep nova sem justificativa de peso.
3. **Ordem**: P0 → melhorias nos existentes → P1. Cada widget é uma UC independente; fatiar por widget, não por onda (uma UC gigante "P0" é infatiável em review).

---

## 4. Contrato técnico de execução (lições da EPIC10 — não negociar)

1. **Gherkin ↔ código, paridade total**: nenhuma linha de `Examples` sem teste correspondente. Linha não implementada = linha removida + nota `> Diferimento formal` fora do fence, nunca promessa silenciosa.
2. **Prova negativa por teste novo**: teste que passa com a implementação quebrada é tautológico e será reprovado no Gate 3. Padrão mínimo: (a) caso positivo, (b) 2 negativos (ex.: lista vazia → empty; erro → retry chama o comando de novo). Para `AsyncListView`/`SearchableSelect`, teste com fonte assíncrona controlada (completer/fake), nunca com delay real.
3. **Sem teste duplicado**: dois blocos com mesmo nome/corpo no mesmo arquivo = reprovação mecânica. Conferir com grep por nome antes de commitar.
4. **Diff Budget por UC**: 1 widget = `lib/src/<widget>.dart` + barrel + `test/<widget>_test.dart` + README/CHANGELOG do pacote. Arquivo fora do slice reprova.
5. **Dispose e async**: widget que assina stream/future cancela no `dispose` (teste com widget descartado no meio do voo — sem exceção em zona); `TextEditingController`/focus criados no widget têm dono explícito.
6. **Todo teste prevê leak (critério de Gate 3, padrão UC-12.00)**: teardown com descarte explícito + assert de `isDisposed`/remoção por teste, cada um com prova negativa executada (remover o `dispose` tem de reprovar). Teste de widget/controller sem isso reprova, salvo justificativa.
7. **Status do épico**: seção de UC só vira `Concluído` com os itens acima verificados; DoD marcada só com evidência (`flutter analyze` + `flutter test` do pacote + contagem antes/depois).

---

## 5. Parecer Técnico (Revisão)

1. **Decisão `PresenterScope` vs `KortexScope` (bloqueante da §3.1)**: unificar em `KortexScope` + `IKortexController` (depreciando `PresenterView`/`PresenterScope` em ciclo menor), evitando manter dois grafos de escopo paralelos na mesma biblioteca.
2. **`AsyncListView` e `AsyncPage`**: garantir suporte explícito a **paginação por cursor/offset** com proteção contra corrida entre `refresh()` e `loadMore()`, além de `SkeletonList` com altura fixa por item para evitar *layout shift* (reflow).
3. **`SearchableSelect` e `DateField`/`DateRangeField`**: manter o estado de filtro/busca isolado em `KortexSignal` local descartado no `dispose`, e nunca acoplar `DateField` a `intl` pesado no núcleo — formatação `dd/MM/yyyy` pode ser pura em Dart.
4. **`OfflineBanner`**: receber `Stream<bool>` (ou `IKortexReadonlySignal<bool>`) injetado pelo consumidor, sem acoplar o `kortex_widgets` a `connectivity_plus` no `pubspec.yaml`.

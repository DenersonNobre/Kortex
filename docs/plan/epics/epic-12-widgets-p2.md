# Épico 12: Segunda onda de widgets — `kortex_widgets` (`EPIC12`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC12` |
| **Dependências Diretas** | `EPIC11` (`kortex_widgets` existe com primitivos + campos BR) |
| **Prioridade** | Alta (P0 é necessidade extrema com gap no `pub.dev`) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Proposto` |
| **Referências** | [kortex_widgets_p2.md](../../proposals/kortex_widgets_p2.md) (incl. §4 contrato técnico e §5 parecer) · [EPIC11](epic-11-kortex-br.md) · [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Completar o `kortex_widgets` com padrões de tela inteira (listas, páginas, seletores, filtros, formulários) integrados a `kortex`/`kortex_forms`, e melhorar os primitivos existentes — sem regra de negócio e sem dependências pesadas novas.

- **Incluso**: UC-12.00 (pré-requisito de escopo) + onda P0 (UC-12.01..UC-12.08) + melhorias (UC-12.09..UC-12.11) + onda P1 (UC-12.12..UC-12.16).
- **Não Incluso / Fora do Escopo**: widgets de domínio; widgets BR novos (casa: `src/br/`, proposta `kortex_br.md`); acoplar `connectivity_plus`, `intl` ou shimmer pesado ao pacote.

### Guardrails (da proposta §4 — resumo; vale o texto integral)

- Gherkin ↔ código, paridade total; diferimento formal fora do fence.
- Prova negativa por teste (1 positivo + 2 negativos; fonte assíncrona controlada).
- Sem teste duplicado; Diff Budget por UC (1 widget = lib + barrel + teste + README/CHANGELOG).
- Dispose com dono explícito; teste de descarte em voo sem exceção em zona.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID | Título | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-12.00** | Unificar escopo: aposentar `PresenterScope` | Nenhuma (DoR do épico) | `Concluído` |
| **UC-12.01** | `AsyncListView` (lista paginada + estados) | `UC-12.00` | `Concluído` |
| **UC-12.02** | `AsyncPage` (scaffold de recurso) | `UC-12.00` | `Concluído` |
| **UC-12.03** | `SearchableSelect` (single/multi, bottom sheet) | `UC-12.00` | `Concluído` |
| **UC-12.04** | `FilterPanel` (chips/filtros reativos) | `UC-12.00` | `Concluído` |
| **UC-12.05** | `FormErrorSummary` + scroll-to-first-error | `UC-12.00` | `Proposto` |
| **UC-12.06** | `DateField` / `DateRangeField` | `UC-12.00` | `Proposto` |
| **UC-12.07** | `OfflineBanner` (faixa de conectividade) | `UC-12.00` | `Proposto` |
| **UC-12.08** | `SkeletonList` (esqueleto estável) | `UC-12.00` | `Proposto` |
| **UC-12.09** | `SearchPanel` async + retry em `StateViews`/`SnapshotBuild` | `UC-12.01` | `Proposto` |
| **UC-12.10** | `BusyOverlay` por operação + sheet padrão em `modals` | `UC-12.00` | `Proposto` |
| **UC-12.11** | Pente de acessibilidade nos widgets | `UC-12.01`..`UC-12.10` | `Proposto` |
| **UC-12.12** | `WizardStepper` | `UC-12.05` | `Proposto` |
| **UC-12.13** | `ResponsiveDataView` | `UC-12.01` | `Proposto` |
| **UC-12.14** | `PermissionGate` | `UC-12.00` | `Proposto` |
| **UC-12.15** | `UploadTile` (progresso + retry + cancel) | `UC-12.00` | `Proposto` |
| **UC-12.16** | `OtpPinField` (se `pinput` não bastar) | `UC-12.00` | `Concluído` (doc-only: guia `pinput`+`KortexField`, ver spike) |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] `UC-12.00` concluído antes de qualquer widget novo (nenhum depende de `PresenterScope`).
- [ ] Cada UC com Gherkin executável, prova negativa e Diff Budget respeitado (§4 da proposta).
- [ ] `flutter analyze` verde; `flutter test` verde em `kortex_widgets` com contagem ≥ baseline (port EPIC11 + novos).
- [ ] Sem nova dependência de terceiros sem justificativa de peso registrada.
- [ ] `CHANGELOG.md`, READMEs ("quando usar/quando NÃO usar"), `LEARNINGS.md`, `CHECKPOINT.md` e status atualizados.

---

## 4. Casos de Uso Atômicos

### UC-12.00 — Unificar escopo: aposentar `PresenterScope`

- **Identificador**: `UC-12.00`
- **Status**: `Concluído`
- **DoR do épico**: sem este UC, nenhum outro inicia.

#### Narrativa

- **Como** mantenedor do ecossistema
- **Eu quero** um único mecanismo de escopo (`KortexScope` + `IKortexController`)
- **Para que** dois grafos de escopo paralelos não coexistam na mesma biblioteca

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Migração de escopo
  Dado um widget sob PresenterScope<presenter>
  Quando migrado para KortexScope + IKortexController
  Então o comportamento é <resultado>

  Exemplos:
    | condição | resultado |
    | resolução em teste | mesmo presenter resolvido, sem InheritedWidget próprio |
    | PresenterScope usado | @Deprecated apontando KortexScope (ciclo menor) |
    | grep por PresenterScope em exemplo/doc novo | zero ocorrências |
```

### UC-12.01 — `AsyncListView`

- **Identificador**: `UC-12.01`
- **Status**: `Concluído`

#### Narrativa

- **Como** desenvolvedor de telas com lista
- **Eu quero** paginação, refresh e estados numa peça só ligada a `KortexResource`
- **Para que** loading/empty/error/retry/skeleton não sejam reescritos por tela

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Lista assíncrona
  Dado um AsyncListView ligado a recurso com <condicao>
  Quando <evento>
  Então <resultado>

  Exemplos:
    | condicao | evento | resultado |
    | página 1 carregada | scroll até o fim | loadMore sem duplicar itens |
    | loadMore em voo | refresh() | corrida resolvida: refresh vence, sem itens fantasmas |
    | erro no loadMore | retry | só a cauda recarrega, lista preservada |
    | loading inicial | primeiro frame | skeleton de altura fixa, sem layout shift |
```

### UC-12.02 — `AsyncPage`

- **Identificador**: `UC-12.02`
- **Status**: `Concluído` (`997e02c`; `flutter analyze` limpo, `flutter test` +88 verdes no pacote)

#### Narrativa

- **Como** desenvolvedor de telas de detalhe
- **Eu quero** `KortexResource<T>` → loading/error(retry)/content com refresh
- **Para que** o `switch` de estado não se repita por tela

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Página de recurso
  Dado AsyncPage com recurso em <estado>
  Quando <evento>
  Então <resultado>

  Exemplos:
    | estado | evento | resultado |
    | loading | dados chegam | content sem flash de empty |
    | error | retry | recarrega e exibe loading |
    | error | — | botão retry visível + mensagem acessível |
```

### UC-12.03 — `SearchableSelect`

- **Identificador**: `UC-12.03`
- **Status**: `Concluído` (`927c5db`; `flutter analyze` limpo, `flutter test` +93 verdes no pacote)

#### Narrativa

- **Como** desenvolvedor de formulários
- **Eu quero** seleção single/multi com busca e opções assíncronas em bottom sheet
- **Para que** não dependa de pacote pesado alheio ao reativo

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Seleção com busca
  Dado SearchableSelect multi com busca em voo
  Quando o usuário digita novo termo
  Então a busca antiga é cancelada e só o último resultado renderiza
  E ao confirmar, o KortexField recebe os selecionados
```

### UC-12.04 — `FilterPanel`

- **Identificador**: `UC-12.04`
- **Status**: `Concluído` (`3a10013`; `flutter analyze` limpo, `flutter test` +98 verdes no pacote)

#### Narrativa

- **Como** desenvolvedor de telas com filtro
- **Eu quero** chips single/multi sincronizados com signals de filtro
- **Para que** filtro não seja fonte de bug layout+estado (cf. POC)

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Filtro reativo estável
  Dado FilterPanel com chips de largura variável
  Quando a seleção muda
  Então a largura dos chips não muda (sem checkmark que reflow) e o teste geométrico (getRect idêntico entre frames) passa
```

### UC-12.05 — `FormErrorSummary`

#### Narrativa

- **Como** usuário de form longo
- **Eu quero** lista de erros com toque-para-navegar até o campo
- **Para que** erro não se perca fora da viewport

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Resumo de erros
  Dado KortexForm com 2 campos inválidos
  Quando submit() falha
  Então o summary lista os 2 erros e o toque no item rola até o campo
```

### UC-12.06 — `DateField` / `DateRangeField`

#### Narrativa

- **Como** desenvolvedor de formulários
- **Eu quero** picker + máscara + validação ligados a `KortexField`, sem `intl`
- **Para que** data BR (`dd/MM/yyyy`, parsing puro Dart) não seja curva alta

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Campo de data
  Dado DateField com texto parcial inválido ("31/02/2026")
  Quando valida
  Então erro de data inválida (sem throw); T range com fim < início é inválido
```

### UC-12.07 — `OfflineBanner`

#### Narrativa

- **Como** desenvolvedor offline-first
- **Eu quero** faixa sem-conexão/sincronizando com retry, sem `connectivity_plus` no pacote
- **Para que** o widget receba `Stream<bool>`/signal injetado e não pisque em flapping (debounce)

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Banner de conectividade
  Dado flapping (offline→online→offline em 300ms com debounce 1s)
  Quando os eventos chegam
  Então o banner não pisca (nenhum rebuild visível no teste de frames)
```

### UC-12.08 — `SkeletonList`

#### Narrativa

- **Como** desenvolvedor de loading states
- **Eu quero** esqueleto com N itens e layout estável
- **Para que** a troca skeleton→dados não cause reflow

#### Critérios (Gherkin)

```gherkin
Esquema do Cenário: Esqueleto estável
  Dado SkeletonList com N itens de altura fixa
  Quando os dados chegam e a lista real renderiza
  Então a altura total ocupada não muda além da tolerância (assert geométrico)
```

### UC-12.09 — `SearchPanel` async + retry em estados

- **Status**: `Proposto`
- **Escopo**: variante de `SearchPanel` com sugestões assíncronas (debounce + cancelamento da busca anterior); `StateViews`/`SnapshotBuild` com retry ligado a `KortexCommand` e predicado de "vazio" customizável (lista vazia ≠ erro). Gherkin: busca antiga cancelada; retry re-despacha o comando; `emptyBuilder` usado só quando predicate decide vazio.

### UC-12.10 — `BusyOverlay` por operação + sheet padrão

- **Status**: `Proposto`
- **Escopo**: overlay escopado por operação (dois comandos simultâneos sem se anularem; teste com 2 `KortexCommand` concorrentes); sheet padrão em `modals` com drag handle + safe area + keyboard avoidance (campo focado nunca sob o teclado — assert de `tester` com viewInsets).

### UC-12.11 — Pente de acessibilidade

- **Status**: `Proposto`
- **Dependências**: `UC-12.01`..`UC-12.10`
- **Escopo**: `semanticsLabel`, contraste, alvo 48dp em todos os widgets do pacote (novos + existentes); teste com `SemanticsTester`/guideline assertions onde aplicável. Sem mudança de comportamento visual além do necessário.

### UC-12.12 — `WizardStepper`

- **Status**: `Proposto`
- **Dependências**: `UC-12.05`
- **Escopo**: passos com validação por etapa (não avança com etapa inválida), preservação de estado entre passos, resumo final sobre os `KortexForm`s. Gherkin: voltar preserva valores; submit final valida tudo.

### UC-12.13 — `ResponsiveDataView`

- **Status**: `Proposto`
- **Dependências**: `UC-12.01`
- **Escopo**: tabela no desktop, cards no mobile, mesma fonte de dados; teste com larguras de viewport distintas (`tester.view.physicalSize`) provando o breakpoint.

### UC-12.14 — `PermissionGate`

- **Status**: `Proposto`
- **Escopo**: rationale → request → "abrir configurações", com re-checagem ao voltar do settings; dependência de `permission_handler` (ou similar) **isolada neste eixo** com justificativa de peso, ou widget recebe capability injetada (preferido — sem dep nova). Decidir no fatiamento.

### UC-12.15 — `UploadTile`

- **Status**: `Proposto`
- **Escopo**: arquivo/imagem com progresso, retry e cancelamento sobre o client `rest/`; teste com fonte controlada (completer) cobrindo cancel no meio do voo sem exceção em zona.

### UC-12.16 — `OtpPinField`

- **Identificador**: `UC-12.16`
- **Status**: `Concluído` (doc-only, `2659291`; veredito do spike `USAR_PINPUT`, sem widget próprio)

- **Status**: `Proposto`
- **Escopo**: **primeiro avaliar `pinput`** (consolidado): só implementar se a integração `KortexField` + requisitos (paste, autofill SMS, acessibilidade) justificarem. Se `pinput` bastar, este UC vira doc de integração em vez de código.

---

## 5. Ordem sugerida de execução

1. **UC-12.00** (pré-requisito, bloqueia o resto).
2. **Fase A (P0)**: `UC-12.01` → `UC-12.02` → `UC-12.03` → `UC-12.04` → `UC-12.05` → `UC-12.06` → `UC-12.07` → `UC-12.08`.
3. **Fase B (melhorias)**: `UC-12.09`, `UC-12.10` (paralelizáveis), depois `UC-12.11` (varre tudo).
4. **Fase C (P1)**: `UC-12.12`..`UC-12.16` por valor/demanda real (podem virar EPIC14 se a Fase A+B já for release).

## 6. Riscos e dependências

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| `UC-12.00` ignorado | Dois escopos convivem; widgets novos no lugar errado | DoR: nenhum widget novo antes dele |
| Dependência pesada por 1 widget | `kortex_widgets` engorda para todos | Eixo separado ou sem dep (decisão por UC, ex. 12.14/12.16) |
| Fase C incha a EPIC | Release demora | Fatiar P1 para EPIC14 se necessário |
| Teste geométrico flaky | CI instável | Tolerância explícita + `pumpAndSettle` determinístico (lição POC) |

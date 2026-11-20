# Épico 06: App de Visitas Técnicas (`EPIC06`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC06` |
| **Dependências Diretas** | `EPIC05` |
| **Prioridade** | Alta (POC evoluída para domínio real de campo) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) (consumo; sem alteração de API do pacote) |

---

## 1. Objetivo de Negócio & Escopo

Evoluir a POC do `example/`/`poc/` para um **app de visitas técnicas**: o técnico visita o cliente, executa um checklist de atendimento e registra o conclusão.

- **Agregados**: `Visit` (raiz, com itens de checklist), `Client` (site), `Technician` (equipe), `ServiceCategory` (tipo de serviço).
- **NÃO incluindo / Fora do Escopo**: backend real, push, geolocalização, assinatura, fotos, faturamento (fora da `v0.1.0` do pacote).
- **Substitui**: o módulo `tasks` da POC — a mesma estrutura VSA, agora com domínio de campo.

## 2. Premissas do Oráculo exercitadas por este épico

| Premissa | Onde aparece |
| --- | --- |
| VSA por feature (`domain/data/commands/ui`) | `poc/lib/modules/visits/` |
| `Result<T>` em vez de exceção | todo command/query da POC |
| Port + Adapter | `VisitRepository`/`ClientRepository`/`TechnicianRepository` + stores em memória |
| Fachada de casos de uso | `VisitUseCases` (1 dependência no controller) |
| CQRS leve | `ListVisitsQuery` (leitura com join) × commands (escrita) |
| `KortexScope` + `KortexScope.capture` | dialog de nova visita e filtro por status |
| `KortexResource` + `KortexCommand` | carga assíncrona com `previousValue`/retry e trava de duplo clique |
| `KortexWatch`/`KortexSelector`/`KortexListener` | lista, filtro por status, `SnackBar` de erro |

## 3. Matriz de Casos de Uso (Feature Matrix)

| ID | Título | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-06.01** | Domínio de visitas, `Result`, ports e stores assíncronos | Nenhuma | `Concluído` |
| **UC-06.02** | Commands, queries com join e fachada `VisitUseCases` | `UC-06.01` | `Concluído` |
| **UC-06.03** | Controller, páginas (lista, detalhe) e dialog de nova visita | `UC-06.02` | `Concluído` |

## 4. Definição de Pronto (DoD) do Épico

- [x] UCs `UC-06.01..03` sob TDD Red-Before-Green.
- [x] `poc/` sem dependências externas e com `flutter analyze` limpo.
- [x] Suíte do `poc/` verde com o gate de leak tracking ligado.
- [x] `example/` (público) intocado e ainda verde.

## 5. Casos de Uso Atômicos

### Caso de Uso UC-06.01 — Domínio de visitas, `Result`, ports e stores

- **Identificador**: `UC-06.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** responsável técnico
- **Eu quero** registrar visita, checklist, cliente e técnico com VOs validados
- **Para que** as regras do atendimento vivam no domínio puro, testável sem Flutter

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Invariantes do dominio de visitas
  Dado um <campo> com <valor>
  Quando crio <objeto>
  Então o resultado é <resultado>

  Exemplos:
    | campo | valor | objeto | resultado |
    | título da visita | "" | VisitTitle.create | Fail VISIT_TITLE_EMPTY |
    | título da visita | 141 caracteres | VisitTitle.create | Fail VISIT_TITLE_TOO_LONG |
    | status | "concluida" (typo) | VisitStatus.parse | Fail VISIT_STATUS_INVALID |
    | checklist | item sem descrição | ChecklistItem.create | Fail CHECKLIST_DESCRIPTION_EMPTY |
    | cliente | telefone inválido | Client.create | Fail CLIENT_PHONE_INVALID |
    | técnico | especialidade vazia | Technician.create | Fail TECHNICIAN_SPECIALTY_EMPTY |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-06.01` | `INV-05` do pacote | Imports Flutter em `domain/` | `0` | `flutter analyze` |
| `UC-06.01` | `RNF-05` | Stores com latência e falha simuladas | `2` mecanismos | Teste com `Completer` |

### Caso de Uso UC-06.02 — Commands, queries e fachada

- **Identificador**: `UC-06.02`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** responsável técnico
- **Eu quero** agendar, iniciar, concluir visitas e marcar itens do checklist
- **Para que** a falha de negócio vire `Fail` (nunca exceção) e o controller injete uma única dependência

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Commands de visita com Result e invariantes cross-agregado
  Dado o estado <estado_inicial>
  Quando executo <comando>
  Então recebo <resultado> e o estado fica <efeito>

  Exemplos:
    | estado_inicial | comando | resultado | efeito |
    | 1 cliente, 1 técnico | scheduleVisit | Ok(Visit) | 1 visita agendada |
    | sem cliente | scheduleVisit | Fail CLIENT_NOT_FOUND | 0 visitas |
    | visita agendada | startVisit | Ok(Visit) | status = IN_PROGRESS |
    | visita já em andamento | startVisit | Fail VISIT_ALREADY_STARTED | status inalterado |
    | visita em andamento | toggleChecklistItem | Ok(item) | item.done invertido |
    | visita concluída | completeVisit | Ok(Visit) | status = COMPLETED |
    | visita em andamento | completeVisit | Fail VISIT_NOT_IN_PROGRESS | status inalterado |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-06.02` | Calisthenics | Métodos com `else` de validação ou >1 nível | `0` | Revisão + `flutter analyze` |

### Caso de Uso UC-06.03 — Controller, páginas e dialog

- **Identificador**: `UC-06.03`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** responsável técnico
- **Eu quero** ver a lista de visitas, o detalhe com checklist e agendar nova visita
- **Para que** o app prove o ciclo reativo completo, com carga assíncrona e erro visível

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Fluxo do app de visitas
  Dado o app com <estado>
  Quando interajo via <acao>
  Então observo <resultado>

  Exemplos:
    | estado | acao | resultado |
    | lista carregando | abrir o app | indicador de carga |
    | lista carregada | tocar numa visita | detalhe com checklist |
    | lista com erro | tocar em "Tentar de novo" | lista recarrega |
    | detalhe em andamento | marcar item | item aparece concluido |
    | qualquer | salvar visita com titulo vazio | SnackBar de erro |
    | lista | abrir dialog de nova visita | dialog com acesso ao escopo (capture) |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-06.03` | `NFR-04` | `setState` após `!mounted` | `0` | `flutter test` |
| `UC-06.03` | `INV-02` | Atualizações tardias após `dispose()` | `0` | `flutter test` |

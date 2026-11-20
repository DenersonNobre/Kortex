# Épico 07: Clientes & Agenda (`EPIC07`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC07` |
| **Dependências Diretas** | `EPIC06` |
| **Prioridade** | Alta (profissionalização do app de campo) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Em Andamento` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) (consumo; sem alteração de API do pacote) |

---

## 1. Objetivo de Negócio & Escopo

Tornar a POC de visitas técnicas utilizável no dia a dia de campo: **data e hora agendadas** na visita, **cadastro/consulta de clientes** e **navegação** entre áreas (Visitas, Agenda, Clientes).

- **Incluso**: `Visit.scheduledAt` (data+hora validada), ordenação e agrupamento por dia, tela de Clientes (listar/criar), tela de Agenda (visitas por dia, com seletor de data), `NavigationBar` de 3 áreas e navegação com `Navigator` nativo.
- **Fora do Escopo**: roteador de terceiros (o pacote é explicitamente contra roteador próprio), backend real, notificações, edição de cliente, exclusão de visita.
- **Premissa de produto**: agendar no passado é **falha de negócio** (`VISIT_IN_PAST`), não exceção.

## 2. Premissas do Oráculo exercitadas

| Premissa | Onde aparece |
| --- | --- |
| VOs validados com `Result` | `ScheduledAt` (data+hora futura) |
| Command com invariante | `ScheduleVisitCommand` valida a data |
| Query com agregação | `AgendaQuery` (agrupa por dia) |
| CQRS leve | listagens por status × por dia |
| Fachada de casos de uso | `VisitUseCases` ganha `listAgenda` |
| UI `StatelessWidget` | novas telas como `IKortexPage` |
| `KortexScope` por subárvore | escopo por área (agenda/clientes) |

## 3. Matriz de Casos de Uso

| ID | Título | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-07.01** | `ScheduledAt` no domínio, validação e ordenação | Nenhuma | `Concluído` |
| **UC-07.02** | Tela e controller de Clientes | `UC-07.01` | `Pendente` |
| **UC-07.03** | Agenda por dia e navegação entre áreas | `UC-07.02` | `Pendente` |

## 4. Definição de Pronto (DoD)

- [ ] UCs `UC-07.01..03` sob TDD Red-Before-Green.
- [ ] `poc/` com `flutter analyze` limpo e suíte verde (inclui os testes de `EPIC06`).
- [ ] App executável no Windows com as 3 áreas navegáveis.

## 5. Casos de Uso Atômicos

### Caso de Uso UC-07.01 — `ScheduledAt` no domínio

- **Identificador**: `UC-07.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** responsável técnico
- **Eu quero** agendar a visita com data e hora
- **Para que** a agenda reflita o compromisso real, sem datas inválidas

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Validação da data/hora agendada
  Dado <agora> e <valor>
  Quando crio ScheduledAt
  Então o resultado é <resultado>

  Exemplos:
    | agora | valor | resultado |
    | fixo  | agora + 1 dia | Ok (normalizado ao minuto) |
    | fixo  | agora - 1 hora | Fail VISIT_IN_PAST |
    | fixo  | null/ausente | Fail VISIT_SCHEDULED_AT_REQUIRED |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-07.01` | Determinismo | Validação recebe `now` injetado | `100%` | `flutter test` (sem `DateTime.now` no domínio) |

### Caso de Uso UC-07.02 — Tela e controller de Clientes

- **Identificador**: `UC-07.02`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** responsável técnico
- **Eu quero** ver e cadastrar clientes
- **Para que** a visita seja sempre vinculada a um site existente

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Clientes na POC
  Dado a tela de Clientes em <estado>
  Quando <acao>
  Então <resultado>

  Exemplos:
    | estado | acao | resultado |
    | vazia | abrir a área Clientes | "Nenhum cliente" |
    | vazia | cadastrar "Empresa X" + telefone válido | cliente na lista |
    | com 1 cliente | cadastrar telefone inválido | SnackBar de erro, lista inalterada |
```

### Caso de Uso UC-07.03 — Agenda por dia e navegação

- **Identificador**: `UC-07.03`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** técnico em campo
- **Eu quero** ver as visitas do dia e navegar entre Visitas, Agenda e Clientes
- **Para que** eu saiba a ordem do dia sem procurar na lista geral

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Agenda e navegação
  Dado a Agenda em <estado>
  Quando <acao>
  Então <resultado>

  Exemplos:
    | estado | acao | resultado |
    | 2 visitas em dias diferentes | abrir a Agenda no dia da 1a | mostra só a 1a |
    | dia sem visitas | abrir a Agenda | "Nenhuma visita neste dia" |
    | qualquer | tocar em "Clientes" na barra | área de Clientes visível |
    | qualquer | tocar em "Visitas" na barra | lista geral visível novamente |
```

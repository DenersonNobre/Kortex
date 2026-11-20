# Épico 08: Módulos de Clientes & Técnicos (`EPIC08`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC08` |
| **Dependências Diretas** | `EPIC07` |
| **Prioridade** | Alta (correção de fronteira de Bounded Context) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) (consumo) |

---

## 1. Objetivo de Negócio & Escopo

Corrigir a fronteira de contexto da POC: `Client` e `Technician` hoje vivem em `modules/visits/`, e os commands de cadastro estão na fachada de **visitas**. Cada agregado passa a ter **módulo próprio** (`domain`, `data`, `commands`, `features`), com a fachada de casos de uso correspondente; `visits` consome as **portas** dos outros contextos (validação de existência e join de nomes).

**Decisão de domínio (modelo A — POC)**: o técnico **é o usuário da sessão**. A visita nasce atribuída a ele e guarda o **nome do técnico como snapshot** (`technicianName`), sem agregado `Technician` nem seleção no formulário. Delegação por papel fica **fora da POC** (o produto real resolveria isso com identidade vinda do servidor).

- **Incluso**: `modules/clients/{domain,data,commands,features}`, `modules/session/` (usuário atual: nome + especialidade), `ClientUseCases`, `UpdateClientCommand`, remoção do agregado `Technician` (substituído por `Visit.technicianName`), rewire de `visits` (query com join de cliente) e controllers/páginas ajustados.
- **Fora do Escopo**: backend real, autenticação/delegação por papel, exclusão de cliente com visitas (regra futura), UI de técnicos.
- **Decisão de dependência entre contextos**: `visits` **pode** depender da **porta** (`ClientRepository`/`TechnicianRepository`) para validar e resolver nomes; nunca do store concreto.

## 2. Premissas do Oráculo exercitadas

| Premissa | Onde aparece |
| --- | --- |
| Bounded context por agregado | `modules/clients`, `modules/technicians` |
| Porta + adapter por contexto | `ClientRepository`/`TechnicianRepository` + stores no próprio módulo |
| Fachada de casos de uso por módulo | `ClientUseCases`, `TechnicianUseCases` |
| DIP entre contextos | `visits` depende da **porta**, não do store |
| Command com `Result` | `CreateClientCommand`, `UpdateClientCommand` |
| UI `StatelessWidget` | `ClientsPage` consome `ClientUseCases` |

## 3. Matriz de Casos de Uso

| ID | Título | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-08.01** | Módulo `clients` (domínio, port, store, commands, fachada) | Nenhuma | `Concluído` |
| **UC-08.02** | Sessão (usuário = técnico) e remoção do agregado `Technician` | `UC-08.01` | `Concluído` |
| **UC-08.03** | `visits` consumindo a porta de clientes e UI ajustada | `UC-08.02` | `Concluído` |

## 4. Definição de Pronto

- [x] UCs `UC-08.01..03` sob TDD Red-Before-Green.
- [x] Nenhuma referência ao agregado `Client`/`Technician` dentro de `modules/visits/domain|data`.
- [x] `poc/` com `flutter analyze` limpo e suíte verde (incluindo testes de `EPIC06`/`EPIC07`).
- [x] App executável com cadastro de cliente e agendamento atribuído ao usuário da sessão.

## 5. Casos de Uso Atômicos

### Caso de Uso UC-08.01 — Módulo `clients`

- **Identificador**: `UC-08.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor mantendo a POC
- **Eu quero** que clientes tenham domínio, dados, commands e fachada próprios
- **Para que** a fronteira do contexto seja explícita e o cadastro de cliente não dependa da fachada de visitas

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Modulo de clientes autonomo
  Dado o modulo clients com <estado>
  Quando executo <comando>
  Então <resultado>

  Exemplos:
    | estado | comando | resultado |
    | vazio | CreateClientCommand("Empresa X", "11988887777") | Ok(Client) com id |
    | vazio | CreateClientCommand("Empresa X", "1") | Fail CLIENT_PHONE_INVALID |
    | 1 cliente | UpdateClientCommand(id, "Novo Nome") | Ok(Client) atualizado |
    | 1 cliente | UpdateClientCommand(99, "X") | Fail CLIENT_NOT_FOUND |
    | 2 clientes | ClientUseCases.listClients(search: "alfa") | so o que casa |
```

### Caso de Uso UC-08.02 — Sessão (usuário = técnico)

- **Identificador**: `UC-08.02`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** técnico em campo
- **Eu quero** que as visitas que eu crio já venham no meu nome
- **Para que** eu não precise escolher técnico a cada agendamento

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Usuario da sessao como tecnico da visita
  Dado a sessao com usuario <usuario>
  Quando agendo uma visita
  Então a visita guarda <tecnico> como tecnico

  Exemplos:
    | usuario | tecnico |
    | Ana (Rede) | "Ana" |
    | Bruno (Software) | "Bruno" |
```

### Caso de Uso UC-08.03 — `visits` sobre as portas

- **Identificador**: `UC-08.03`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** usuário do app
- **Eu quero** agendar visita para um cliente cadastrado no módulo de clientes
- **Para que** a visita continue funcionando sem conhecer os stores concretos

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Visitas consumindo a porta de clientes
  Dado <estado> no modulo de clientes
  Quando executo <acao> em visitas
  Então <resultado>

  Exemplos:
    | estado | acao | resultado |
    | cliente existente | ScheduleVisitCommand | Ok(Visit) |
    | cliente inexistente | ScheduleVisitCommand | Fail CLIENT_NOT_FOUND |
    | 1 visita | ListVisitsQuery | nome do cliente resolvido e tecnico da sessao |
```

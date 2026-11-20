# Épico 05: POC Robusta — Premissas Oráculo no `example/` (`EPIC05`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC05` |
| **Dependências Diretas** | `EPIC04` |
| **Prioridade** | Alta (Prova viva das premissas de engenharia) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Em Andamento` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) (somente consumo; sem alteração de API) |

---

## 1. Objetivo de Negócio & Escopo

Evoluir o `example/` de app mínimo para POC robusta que demonstra, em código executável e testado, as premissas de programação do Oráculo (`architecture-guidelines.md`): Vertical Slices por feature, CQRS leve (query × command), `Result` em vez de exceção para falha esperada, Port (`TaskRepository`) + Adapter (`InMemoryTaskRepository`), fachada de casos de uso (`TaskUseCases`, sem over-injection no controller), `IKortexController` sem `onInit` mágico e UI `StatelessWidget`-first.

- **Incluso**: `Result<T>` (`Ok`/`Fail`), `Task` + `TaskTitle` (VO validado), `TaskRepository` (port), `InMemoryTaskRepository` (adapter), 4 slices (`list_tasks`, `create_task`, `toggle_task`, `remove_task`), `TaskUseCases` (fachada), `TasksController`, `TasksPage` + widgets, testes unitários (handlers com InMemory) e de widget (fluxo ponta a ponta).
- **Não Incluso / Fora do Escopo**: qualquer alteração na API de `lib/` (SPEC congelada na `v0.1.0`); persistência real, roteador, backend, dependências externas no `example/` (só `flutter` + `kortex` via path).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-05.01** | Domínio, `Result`, Port e Adapter InMemory | Nenhuma | `Pendente` |
| **UC-05.02** | Commands e fachada `TaskUseCases` | `UC-05.01` | `Pendente` |
| **UC-05.03** | Controller, Page e fluxo de widget | `UC-05.02` | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Todos os Casos de Uso (`UC-05.01..03`) implementados sob TDD Red-Before-Green.
- [ ] `example/` sem dependências externas (`flutter` + `kortex` path apenas).
- [ ] `flutter analyze` e `flutter test` verdes na raiz e em `example/`.
- [ ] `example/README.md` descrevendo o mapa feature→arquivo.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-05.01 — Domínio, `Result`, Port e Adapter

- **Identificador**: `UC-05.01`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** desenvolvedor consumindo o Kortex
- **Eu quero** entidade `Task`, VO validado `TaskTitle`, `Result<T>` selado, port `TaskRepository` e adapter em memória
- **Para que** regras de negócio vivam no domínio puro, testável sem Flutter

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Validação de domínio e contrato do repositório
  Dado um título <titulo>
  Quando crio TaskTitle ou executo <operacao> no InMemory
  Então o resultado é <resultado>

  Exemplos:
    | titulo | operacao | resultado |
    | "" | TaskTitle.create | Fail TASK_EMPTY_TITLE |
    | 121 caracteres | TaskTitle.create | Fail TASK_TITLE_TOO_LONG |
    | "Comprar leite" | save + findAll | lista contém a task |
    | — | toggle de id inexistente no repo | Fail TASK_NOT_FOUND |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-05.01` | `INV-05` do pacote | Imports Flutter em `domain/` e `shared/` do example | `0` | `flutter analyze` / grep |

---

### Caso de Uso UC-05.02 — Commands e Fachada `TaskUseCases`

- **Identificador**: `UC-05.02`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** desenvolvedor de feature
- **Eu quero** commands (`create`/`toggle`/`remove`) devolvendo `Result` e uma fachada `TaskUseCases` agregando os 4 casos de uso
- **Para que** o controller injete 1 dependência (sem over-injection) e falha esperada nunca vire exceção

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Commands via fachada com Result
  Dado um TaskUseCases sobre InMemory em <estado>
  Quando executo <comando>
  Então recebo <resultado> e o repositório fica <efeito>

  Exemplos:
    | estado | comando | resultado | efeito |
    | vazio | create("Estudar") | Ok(Task) | 1 task persistida |
    | vazio | create("") | Fail TASK_EMPTY_TITLE | 0 tasks persistidas |
    | 1 task | toggle(id inexistente) | Fail TASK_NOT_FOUND | lista inalterada |
    | 1 task | remove(id) | Ok | 0 tasks |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-05.02` | Calisthenics | Métodos com >1 nível de indentação ou `else` de validação | `0` | Revisão + `flutter analyze` |

---

### Caso de Uso UC-05.03 — Controller, Page e Fluxo de Widget

- **Identificador**: `UC-05.03`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** usuário do app exemplo
- **Eu quero** adicionar, concluir e remover tasks numa `TasksPage` (`StatelessWidget`) com erros em `SnackBar`
- **Para que** o exemplo prove o ciclo completo reativo sem `StatefulWidget` para estado de negócio

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Fluxo ponta a ponta na TasksPage
  Dado a TasksPage com <estado_inicial>
  Quando interajo via <acao>
  Então observo <resultado>

  Exemplos:
    | estado_inicial | acao | resultado |
    | lista vazia | digitar "Ler" + salvar | item "Ler" visível |
    | 1 task aberta | tocar no checkbox | item marcado como feito |
    | 1 task | excluir | lista vazia |
    | qualquer | salvar título vazio | SnackBar de erro, nada persistido |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-05.03` | `NFR-04` | `setState` após `!mounted` | `0` | `flutter test` |

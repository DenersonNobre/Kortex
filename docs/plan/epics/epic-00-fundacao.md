# Épico 00: Fundação Técnica & Governança (`EPIC00`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC00` |
| **Dependências Diretas** | Nenhuma |
| **Prioridade** | Crítica (Fundação Técnica) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Estabelecer os pilares técnicos F0.1..F0.8 do pacote Flutter `kortex` antes de qualquer código de produção em `lib/src/`, garantindo zero dependências externas, análise estática limpa, suíte de testes funcional e governança documental completa.

- **Incluso**: topologia de pastas (`lib/src/{reactive,scope,widgets}`, `test/`, `docs/`), normalização VCS (`.gitattributes`), validação do toolchain (`flutter analyze`, `flutter test`), arquivo de hand-off (`docs/plan/state/UC-CURRENT.md`) e commit inicial da fundação.
- **Não Incluso / Fora do Escopo**: Docker/OCI (dispensável para biblioteca Dart/Flutter pura conforme `F0.5`) e implementação de primitivas em `lib/src/`.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-00.01** | Topologia, VCS, Toolchain & Governança Documental (F0.1–F0.8) | Nenhuma | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] `pubspec.yaml` com apenas `flutter: sdk: flutter` em `dependencies`.
- [x] `.gitattributes` configurado para normalização LF/CRLF.
- [x] `flutter analyze` com `No issues found!` e `flutter test` verde.
- [x] Quarteto canônico (`SPEC.md`, `DESIGN.md`, `docs/plan/README.md`, `epic-00-fundacao.md`) + `AGENTS.md`, `README.md`, `CHANGELOG.md`, `LEARNINGS.md`, `CHECKPOINT.md` e `docs/plan/state/UC-CURRENT.md` materializados e aprovados.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-00.01 — Topologia, VCS, Toolchain & Governança Documental

- **Identificador**: `UC-00.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** Arquiteto / Desenvolvedor do pacote Kortex
- **Eu quero** validar o esqueleto do pacote, a normalização de arquivos e o quarteto canônico de governança
- **Para que** toda implementação subsequente ocorra com zero dependências externas, análise estática estrita e rastreabilidade completa

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Validação da fundação do pacote Flutter
  Dado que o repositório possui o esqueleto do pacote em <caminho>
  Quando executamos a verificação <comando>
  Então o comando encerra com status <resultado>

  Exemplos:
    | caminho | comando | resultado |
    | pubspec.yaml | flutter analyze | exit 0 (No issues found!) |
    | test/kortex_test.dart | flutter test | exit 0 (All tests passed!) |
    | .gitattributes | git status --short | política LF/CRLF versionada |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-00.01` | `NFR-01` | Dependências externas em `pubspec.yaml` | `0` | Inspeção de `pubspec.yaml` |
| `UC-00.01` | `NFR-02` | Warnings/erros em `flutter analyze` | `0` | `flutter analyze` |

#### Tarefas Técnicas

1. `TASK-01`: Criar `.gitattributes` para normalização LF/CRLF.
2. `TASK-02`: Criar `docs/plan/state/UC-CURRENT.md` para hand-off de execução.
3. `TASK-03`: Validar `flutter analyze` e `flutter test` e realizar commit inicial após aprovação do PO.

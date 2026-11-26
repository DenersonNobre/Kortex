# Épico 13: Split da `kortex_lib` (`EPIC13`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC13` |
| **Dependências Diretas** | `EPIC12` (lar dos widgets estabilizado; evita mover `widgets/` duas vezes) |
| **Prioridade** | Média (dívida de peso no grafo de dependências, não bug funcional) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referências** | [kortex_lib_split.md](../../proposals/kortex_lib_split.md) · [EPIC11](epic-11-kortex-br.md) · [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Eliminar o acoplamento de dependências da `kortex_lib` (`crypto` + `encrypt` + `http` + `sqflite` puxados juntos por qualquer consumidor), extraindo eixos independentes e mantendo `kortex_lib` apenas como barrel opt-in.

- **Incluso**: extração de `kortex_core`, `kortex_rest` e `kortex_sqlite`; `kortex_lib` como barrel fino; migração seletiva de `poc/` e `example/`s; gate automatizado de peso (`dart pub deps --json`) e não-regressão do barrel.
- **Não Incluso / Fora do Escopo**: fatiar `kortex_core` internamente; ORM completo em `kortex_sqlite`; framework opinativo de API em `kortex_rest`.

### Guardrails

- **Mover = código + testes + docs juntos** no mesmo commit atômico (suíte do destino ≥ origem).
- **Exemplos e `poc/` usam import seletivo** (nunca o barrel `kortex_lib`).
- **Sem `pubspec.yaml` próprio em `example/`** enquanto a dependência interna não estiver publicada no `pub.dev`.
- **Sem duplicação residual**: grep por símbolos movidos fora dos re-exports intencionais = 0.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID | Título | Pacote/Área | Dependências Internas | Status |
| --- | --- | --- | --- | --- |
| **UC-13.01** | Extrair `kortex_core` (kernel atual) | `kortex_core` | Nenhuma | `Concluído` |
| **UC-13.02** | Extrair `kortex_rest` (cliente HTTP fino) | `kortex_rest` | `UC-13.01` | `Concluído` |
| **UC-13.03** | Extrair `kortex_sqlite` (porta + adapter) | `kortex_sqlite` | `UC-13.01` | `Concluído` |
| **UC-13.04** | Barrel `kortex_lib` + gate de peso | `kortex_lib` | `UC-13.01`, `UC-13.02`, `UC-13.03` | `Concluído` |
| **UC-13.05** | Migração `poc/`, `README`s e fechamento | `poc/`, docs | `UC-13.04` | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] `kortex_core`, `kortex_rest` e `kortex_sqlite` criados com `example/`, `README.md`, `CHANGELOG.md` e suíte própria verde (`104`, `33` e `11` testes).
- [x] Gate de peso (`dependency_weight_gate_test.dart`) verde: `kortex_core` sem `http`/`sqflite`; `kortex_rest` sem `sqflite`.
- [x] Teste de não-regressão do barrel `kortex_lib` (`barrel_regression_test.dart`) exercitando símbolos de todos os 3 pacotes.
- [x] `flutter analyze` verde nos pacotes afetados.
- [x] `CHECKPOINT.md` e status do épico atualizados.

---

## 4. Casos de Uso Atômicos

### UC-13.01 — Extrair `kortex_core`

- **Identificador**: `UC-13.01`
- **Status**: `Proposto`
- **Pacote**: `kortex_core`

```gherkin
Cenário: kortex_core isola o kernel sem http nem sqflite
  Dado o pacote kortex_core com core/ (Result, Money, patterns, logging, security)
  Quando as dependências resolvidas são inspecionadas
  Então http e sqflite não aparecem no grafo e toda a suíte de core/ passa
```

---

### UC-13.02 — Extrair `kortex_rest`

- **Identificador**: `UC-13.02`
- **Status**: `Proposto`
- **Pacote**: `kortex_rest`

```gherkin
Cenário: kortex_rest oferece cliente HTTP fino sobre http.Client
  Dado o pacote kortex_rest dependendo apenas de http e kortex_core
  Quando testes com MockClient exercitam retry, timeout e middleware
  Então todos os testes passam e sqflite não aparece no grafo
```

---

### UC-13.03 — Extrair `kortex_sqlite`

- **Identificador**: `UC-13.03`
- **Status**: `Proposto`
- **Pacote**: `kortex_sqlite`

```gherkin
Cenário: kortex_sqlite separa porta de persistência e adapter sqflite
  Dado o pacote kortex_sqlite dependendo de sqflite e kortex_core
  Quando migrations e operações são testadas
  Então todos os testes passam com @Deprecated registrado na origem
```

---

### UC-13.04 — Barrel `kortex_lib` + gate de peso

- **Identificador**: `UC-13.04`
- **Status**: `Proposto`
- **Pacote**: `kortex_lib`

```gherkin
Cenário: kortex_lib re-exporta os três pacotes e gate valida peso
  Dado kortex_lib como barrel fino re-exportando kortex_core, kortex_rest e kortex_sqlite
  Quando o teste de não-regressão do barrel e o gate de peso rodam
  Então símbolos dos três pacotes compilam via barrel e os grafos respeitam o isolamento
```

---

### UC-13.05 — Migração `poc/`, `README`s e fechamento

- **Identificador**: `UC-13.05`
- **Status**: `Proposto`
- **Pacote**: `poc/`, docs

```gherkin
Cenário: poc/ e docs usam imports seletivos
  Dado poc/ e os READMEs dos pacotes novos
  Quando a suíte da poc/ e o analyze do workspace executam
  Então todos os testes passam sem imports diretos desnecessários do barrel
```

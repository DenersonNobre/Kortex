# Épico 11: Pacote Brasileiro Kortex (`EPIC11`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC11` |
| **Dependências Diretas** | `EPIC10` (mínimo: `UC-10.03` + `UC-10.05` concluídos) |
| **Prioridade** | Média (evolução do ecossistema; só após hardening de forms e fronteira de API) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Proposto` |
| **Referências** | [kortex_br.md](../../proposals/kortex_br.md) · [EPIC10](epic-10-evolucao-ecossistema.md) · [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Extrair o eixo brasileiro de `kortex_lib` (`brlib/`) para pacote(s) dedicado(s), centralizando validadores, formatadores/máscaras e widgets de entrada para padrões BR, integrados ao `kortex_forms` — sem duplicação entre apps.

- **Incluso**: núcleo puro de validação/formatação/normalização; parser BRL↔centavos (`int`); widgets `KortexXxxField`; migração com `@Deprecated` por um ciclo menor; documentação e guia de migração.
- **Não Incluso / Fora do Escopo**: clientes HTTP acoplados a provedor específico (ViaCEP hardcoded — no máximo porta/interface opcional); regras de negócio de domínio; roteador/service locator/event bus; dependências de terceiros no núcleo puro.

### Decisão arquitetural (ratificar no kickoff)

A proposta (§4) recomenda **dois pacotes**: `kortex_br` (`sdk: dart`, zero deps) + `kortex_br_widgets` (Flutter + `kortex_forms` + `kortex_br`). Se o PO optar por pacote único, fundir `UC-11.01`/`UC-11.02` e abandonar explicitamente o requisito de uso em backend Dart.

### Guardrails

- Núcleo puro: `sdk: dart`, zero dependências de terceiros, nenhum import Flutter (gate no CI, espelhando `INV-05`).
- `Money` permanece no `kortex_lib`: o BRL do `kortex_br` opera em `int` centavos/`String`, sem arrastar o `core/`.
- Migração com SemVer: `@Deprecated` por um ciclo menor + `CHANGELOG.md` + guia; item removido tem justificativa registrada.
- DoR do épico: `UC-10.03` (forms, commit `4f95df9`) e `UC-10.05` (fronteira de API, commit `1833936`) — ambos `Concluídos` com a conclusão da `EPIC10`. Gate **aberto**; o épico pode iniciar.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID | Título | Pacote/Área | Dependências Internas | Status |
| --- | --- | --- | --- | --- |
| **UC-11.01** | Núcleo puro `kortex_br` | `kortex_br` | Nenhuma (DoR: `UC-10.05`) | `Proposto` |
| **UC-11.02** | Widgets `kortex_br_widgets` | `kortex_br_widgets` | `UC-11.01` (+ DoR: `UC-10.03`) | `Proposto` |
| **UC-11.03** | Migração e depreciação no `kortex_lib` | `kortex_lib` | `UC-11.01`, `UC-11.02` | `Proposto` |
| **UC-11.04** | Documentação e guia de migração | todos | `UC-11.03` | `Proposto` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] DoR satisfeito: `UC-10.03` e `UC-10.05` concluídos antes de `UC-11.01`.
- [ ] Todos os validadores com tabela de aceitação (bordas: zeros à esquerda, DVs, repetidos, vazio/sujo, `null`) e testes verdes (incl. fuzz de DV: gerar válido, corromper 1 dígito).
- [ ] Gate "nenhum import Flutter no núcleo" verde no CI.
- [ ] `flutter analyze` verde; `flutter test`/`dart test` verdes nos pacotes afetados.
- [ ] `CHANGELOG.md` dos pacotes afetados + guia de migração publicados no mesmo commit atômico.
- [ ] `LEARNINGS.md`, `CHECKPOINT.md` e status do épico atualizados.

---

## 4. Casos de Uso Atômicos

### UC-11.01 — Núcleo puro `kortex_br`

- **Identificador**: `UC-11.01`
- **Status**: `Proposto`

#### Narrativa (User Story)

- **Como** desenvolvedor Dart/Flutter
- **Eu quero** validadores e formatadores BR como funções puras testáveis
- **Para que** regras de documento/contato/moeda sejam compartilhadas sem depender de widget ou backend específico

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Validação e formatação BR puras
  Dado uma entrada <entrada>
  Quando o validador/formatador <componente> a processa
  Então o resultado é <resultado>

  Exemplos:
    | entrada              | componente          | resultado |
    | 111.111.111-11       | CpfValidator        | inválido (sequência repetida) |
    | CPF válido com 1 DV corrompido | CpfValidator | inválido |
    | " 529.XXX.XXX-XX sujo " | digitsOnly + CpfValidator | normaliza e valida |
    | "R$ 1.234,56"        | parser BRL          | 123456 centavos (int) |
    | "" / null            | qualquer validator  | inválido com mensagem, sem throw |
```

#### Escopo técnico

- CPF/CNPJ (DVs + repetidos), telefone BR, CEP, UF, Pix (gramáticas por tipo: CPF/CNPJ/e-mail/telefone/EVP), placa Mercosul (antigo × novo, tolerância hífen/caixa).
- `digitsOnly`/`unmask` com semântica `null`/vazio consistente com `UC-10.03`.
- Sem `double` no caminho feliz do parser financeiro; sem dependência de `Money`.

### UC-11.02 — Widgets `kortex_br_widgets`

- **Identificador**: `UC-11.02`
- **Status**: `Proposto`
- **Dependências**: `UC-11.01` + DoR `UC-10.03`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter com `kortex_forms`
- **Eu quero** campos prontos (`KortexCpfField`, `KortexCnpjField`, `KortexPhoneBrField`, `KortexCepField`, `KortexBrlCurrencyField`)
- **Para que** máscara, teclado, limite e validação venham configurados e ligados ao `KortexField`

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Campo BR integrado ao KortexField
  Dado um KortexXxxField ligado a um KortexField
  Quando o usuário digita <digitos>
  Então a máscara exibe <mascara> e o erro aparece <quando>

  Exemplos:
    | digitos     | mascara        | quando |
    | 8 dígitos CEP | NNNNN-NNN     | erro some ao completar válido |
    | CPF incompleto + submit | parcial | erro exibido via touchAll |
    | centavos BRL | R$ agrupado   | KortexField<int> recebe centavos |
```

#### Escopo técnico

- Resolver duplicação `currency` vs `money` input formatter (um sobrevive).
- `keyboardType`/`maxLength` documentados por campo; núcleo permanece testável sem widget.

### UC-11.03 — Migração e depreciação no `kortex_lib`

- **Identificador**: `UC-11.03`
- **Status**: `Proposto`
- **Dependências**: `UC-11.01`, `UC-11.02`

#### Narrativa (User Story)

- **Como** consumidor atual do `brlib` via `kortex_lib`
- **Eu quero** um caminho de migração sem quebra silenciosa
- **Para que** eu migre no meu ritmo dentro do ciclo de depreciação

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Depreciação orienta migração
  Dado código usando brlib via kortex_lib
  Quando o analyzer executa após a migração
  Então cada símbolo movido <simbolo> aponta para <destino>

  Exemplos:
    | simbolo | destino |
    | PhoneBrValidator (kortex_lib) | @Deprecated apontando package:kortex_br |
    | símbolo sem equivalente | guia registra "morreu + motivo" |
```

### UC-11.04 — Documentação e guia de migração

- **Identificador**: `UC-11.04`
- **Status**: `Proposto`
- **Dependências**: `UC-11.03`

#### Narrativa (User Story)

- **Como** avaliador do ecossistema
- **Eu quero** READMEs com limites e guia de migração
- **Para que** eu saiba quando usar cada pacote e como migrar

#### Critérios de Aceitação

- README do `kortex_br`/`kortex_br_widgets` com "quando usar / quando NÃO usar".
- Guia de migração `kortex_lib/brlib` → novos pacotes, item a item (§5 da proposta).

---

## 5. Ordem sugerida de execução

1. **Ratificar decisão 1-vs-2 pacotes** no kickoff (se 1 pacote, fundir `UC-11.01`/`UC-11.02`).
2. **UC-11.01** → **UC-11.02** → **UC-11.03** → **UC-11.04**.

## 6. Riscos e dependências

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Iniciar antes de `UC-10.03`/`UC-10.05` | Widgets sobre contrato com bug; migração sem fronteira | Gate de DoR: épico não inicia sem os dois concluídos |
| `Money` arrastado para o novo pacote | Recria acoplamento que o split desfaz | Parser `int`-based; `Money` fica no `kortex_lib` |
| Formatters genéricos (`date`, `integer`) em pacote BR | Escopo incoerente | Decidir por item na tabela §5 da proposta |
| Quebra de consumidores do `brlib` | Migração traumática | `@Deprecated` + CHANGELOG + guia, um ciclo menor |

# Épico 10: Evolução do Ecossistema Kortex (`EPIC10`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC10` |
| **Dependências Diretas** | `EPIC04`, `EPIC09` |
| **Prioridade** | Alta (qualidade de produção, DX e governança do ecossistema) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Proposto` |
| **Referências** | [SPEC.md](../../architecture/SPEC.md) · [LEARNINGS.md](../../../LEARNINGS.md) (2026-11-26) · [README do plano](../README.md) |

---

## 1. Objetivo de Negócio & Escopo

Elevar o ecossistema Kortex de “núcleo funcional publicado” para “ecossistema confiável em produção”, corrigindo riscos de contrato/lifecycle/persistência/segurança identificados na auditoria de 2026-11-26 e entregando capacidades de DX que reduzam boilerplate, bugs reativos e custo de adoção.

- **Incluso**: correções de risco nos pacotes existentes; hardening de API pública; observabilidade/debug; evolução de `kortex_persist`, `kortex_forms`, `kortex_lint` e governança de `kortex_lib`; documentação de padrões e limites.
- **Não Incluso / Fora do Escopo**: roteador próprio, service locator global, event bus global, ORM/sync engine, framework de forms completo, dependências de terceiros no `kortex`/`kortex_persist`, quebra do contrato zero-dep/pureza reativa.

### Guardrails (não negociar)

- `kortex` e `lib/src/reactive/`: zero dependências de terceiros e pureza Dart (`INV-05`).
- Sem globals implícitos (`INV-06`): escopo explícito, lifecycle determinístico.
- Mudança de API pública exige SemVer, migração documentada e testes.
- Item `[risco/bug]` entra com prova negativa (vermelho antes, verde depois).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID | Título | Pacote/Área | Dependências Internas | Status |
| --- | --- | --- | --- | --- |
| **UC-10.01** | Hardening de lifecycle e descarte composto | `kortex` | Nenhuma | `Proposto` |
| **UC-10.02** | Contrato de durabilidade do `KortexPersistedSignal` | `kortex_persist` | Nenhuma | `Proposto` |
| **UC-10.03** | Semântica de reset nullable e ergonomia de forms | `kortex_forms` | Nenhuma | `Proposto` |
| **UC-10.04** | Segurança e posicionamento do `SecretCipher` | `kortex_lib` | Nenhuma | `Proposto` |
| **UC-10.05** | Fronteira pública de API e governança de deps | todos | `UC-10.01` | `Proposto` |
| **UC-10.06** | Observabilidade e diagnóstico em `kDebugMode` | `kortex` | `UC-10.01` | `Proposto` |
| **UC-10.07** | Quick fixes e regras de alto sinal | `kortex_lint` | `UC-10.01` | `Proposto` |
| **UC-10.08** | Documentação “quando usar / quando NÃO usar” | todos | `UC-10.05` | `Proposto` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Todos os UCs `[risco/bug]` têm teste vermelho reproduzido antes do fix e verde após.
- [ ] `flutter analyze` verde no workspace; `flutter test` verde nos pacotes afetados.
- [ ] Sem regressão de `INV-01`, `INV-02`, `INV-05`, `INV-06`.
- [ ] Mudanças de API pública documentadas em `CHANGELOG.md` dos pacotes afetados.
- [ ] `LEARNINGS.md`, `CHECKPOINT.md` e status do épico atualizados no mesmo commit atômico.

---

## 4. Casos de Uso Atômicos

### UC-10.01 — Hardening de lifecycle e descarte composto

- **Identificador**: `UC-10.01`
- **Status**: `Proposto`
- **Pacote**: `kortex`

#### Narrativa (User Story)

- **Como** mantenedor de app Flutter com Kortex
- **Eu quero** que descarte composto seja best-effort e determinístico
- **Para que** uma falha em um cleanup não vaze os demais recursos

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: DisposeBag executa todos os callbacks
  Dado um KortexDisposeBag com callbacks <callbacks>
  Quando dispose() é executado
  Então o resultado é <resultado>

  Exemplos:
    | callbacks                                      | resultado |
    | [ok, throws, ok]                               | todos executados; erro preservado/reportado conforme contrato |
    | [ok, ok]                                       | todos executados; bag marcado como disposed |
    | dispose() chamado duas vezes                   | idempotente; sem reexecução indevida |
```

#### NFRs / Notas

| NFR | Métrica | Target |
| --- | --- | --- |
| Robustez de lifecycle | Callbacks executados após falha | 100% |
| Regressão | Testes existentes de dispose | verdes |

---

### UC-10.02 — Contrato de durabilidade do `KortexPersistedSignal`

- **Identificador**: `UC-10.02`
- **Status**: `Proposto`
- **Pacote**: `kortex_persist`

#### Narrativa (User Story)

- **Como** desenvolvedor que persiste estado local
- **Eu quero** semântica clara para concorrência, erro e confirmação de escrita
- **Para que** estado em memória e storage não divirjam silenciosamente

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Concorrência e falha de persistência
  Dado um KortexPersistedSignal com storage controlado por Completer
  Quando ocorre <sequencia>
  Então o estado observado é <resultado>

  Exemplos:
    | sequencia                                      | resultado |
    | mutate durante hydrate                         | ordem determinística; sem write perdido |
    | clear durante write pendente                   | estado final consistente com contrato documentado |
    | write falha                                    | erro exposto por callback/estado; sem crash silencioso |
    | rajada de mutações com debounceWrite           | escrita coalescida; flush() garante persistência |
```

#### Escopo técnico

- Ordenação/serialização de operações por chave.
- `onReadError/onWriteError` ou estado de erro equivalente.
- `debounceWrite`/`flush()` opt-in.
- `version` + `migrate(raw, fromVersion)` para payload.
- Confirmação de escrita (`Future`/hook) documentada.

---

### UC-10.03 — Semântica de reset nullable e ergonomia de forms

- **Identificador**: `UC-10.03`
- **Status**: `Proposto`
- **Pacote**: `kortex_forms`

#### Narrativa (User Story)

- **Como** desenvolvedor de formulários
- **Eu quero** reset e validação com semântica inequívoca
- **Para que** campos nullable e fluxos async não tenham comportamento surpreendente

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Reset nullable e validação async
  Dado um KortexField<T?> com valor inicial <inicial>
  Quando ocorre <operacao>
  Então o valor/estado é <resultado>

  Exemplos:
    | inicial | operacao                                  | resultado |
    | null    | reset(nextValue: null)                     | valor permanece null explicitamente |
    | "a"     | reset() sem argumento                      | volta ao initialValue |
    | "x"     | async validator em voo + novo valor        | validação antiga cancelada/ignorada |
    | form    | submit() com campo inválido                | touchAll + erros expostos; sem submit |
```

#### Escopo técnico

- Corrigir ambiguidade `T?` (sentinela ou tipo opção).
- Validação async com `validating` e cancelamento.
- `FormGroup`/arrays/campos aninhados (MVP).
- Bindings Flutter opcionais, núcleo puro testável.

---

### UC-10.04 — Segurança e posicionamento do `SecretCipher`

- **Identificador**: `UC-10.04`
- **Status**: `Proposto`
- **Pacote**: `kortex_lib`

#### Narrativa (User Story)

- **Como** consumidor da `kortex_lib`
- **Eu quero** saber exatamente o nível de segurança de `SecretCipher`
- **Para que** eu não use criptografia fraca em contexto sensível

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Posicionamento de segurança
  Dado a documentação pública de SecretCipher
  Quando um desenvolvedor avalia uso em produção
  Então o contrato declara <resultado>

  Exemplos:
    | contexto                         | resultado |
    | segredo de produção              | doc alerta limite; recomenda alternativa/AEAD |
    | ofuscação local não crítica      | uso permitido com aviso explícito |
    | API pública                      | SemVer/migração se contrato mudar |
```

#### Escopo técnico

- Documentar limite atual imediatamente.
- Avaliar redesign para AEAD + KDF com salt/custo adequado; se breaking, planejar major.
- Não prometer “proteção de segredos em produção” sem garantias criptográficas adequadas.

---

### UC-10.05 — Fronteira pública de API e governança de deps

- **Identificador**: `UC-10.05`
- **Status**: `Proposto`
- **Pacote**: todos (ênfase `kortex_lib`)

#### Narrativa (User Story)

- **Como** mantenedor do ecossistema
- **Eu quero** superfície pública pequena e dependências governadas
- **Para que** SemVer seja previsível e o custo de manutenção não cresça invisivelmente

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Export público e dependência nova
  Dado uma mudança em pacote do ecossistema
  Quando a API pública ou dependências são alteradas
  Então o gate exige <resultado>

  Exemplos:
    | mudança                                  | resultado |
    | export acidental de src/*                | falha em revisão/gate; corrigir barrel/@internal |
    | nova dependência em kortex/kortex_persist| rejeitada (zero-dep) |
    | nova dependência em kortex_lib           | justificativa + avaliação de peso/split |
```

#### Escopo técnico

- Auditoria de barrels/`@internal`.
- Política de deps por pacote.
- Critério de split para eixos do `kortex_lib` (`rest`, `sqlite`, `widgets`, `brlib`) quando houver crescimento/autonomia.

---

### UC-10.06 — Observabilidade e diagnóstico em `kDebugMode`

- **Identificador**: `UC-10.06`
- **Status**: `Proposto`
- **Pacote**: `kortex`

#### Narrativa (User Story)

- **Como** desenvolvedor depurando reatividade
- **Eu quero** sinais de diagnóstico opt-in e sem custo em release
- **Para que** eu identifique rebuilds, resoluções e falhas silenciosas rapidamente

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Diagnóstico opt-in
  Dado um app com hooks de debug habilitados em kDebugMode
  Quando ocorre <evento>
  Então o diagnóstico registra <resultado>

  Exemplos:
    | evento                          | resultado |
    | rebuild de KortexWatch          | origem/contagem observável em debug |
    | resolução de provider em scope  | cadeia de resolução visível em debug |
    | falha em Resource/Command       | erro não silencioso no canal de debug |
    | build release                   | hooks sem efeito/custo perceptível |
```

---

### UC-10.07 — Quick fixes e regras de alto sinal

- **Identificador**: `UC-10.07`
- **Status**: `Proposto`
- **Pacote**: `kortex_lint`

#### Narrativa (User Story)

- **Como** desenvolvedor usando Kortex
- **Eu quero** lint que detecte e corrija erros comuns
- **Para que** problemas de lifecycle/reatividade sejam pegos antes do runtime

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Regra com quick fix
  Dado código com <anti_pattern>
  Quando o analyzer do kortex_lint executa
  Então ele reporta <diagnostico> e oferece <fix>

  Exemplos:
    | anti_pattern                        | diagnostico                    | fix |
    | sinal em IKortexController sem dispose| avoid_undisposed_kortex_signal | adicionar autoDispose |
    | primitivo criado em build            | avoid_kortex_signal_in_build   | mover para campo/init |
    | side effect em Computed              | regra nova                     | sugestão de refatoração |
```

---

### UC-10.08 — Documentação “quando usar / quando NÃO usar”

- **Identificador**: `UC-10.08`
- **Status**: `Proposto`
- **Pacote**: todos

#### Narrativa (User Story)

- **Como** desenvolvedor avaliando Kortex
- **Eu quero** limites claros de responsabilidade por pacote
- **Para que** eu não use a ferramenta errada para o problema errado

#### Critérios de Aceitação (Gherkin)

```gherkin
Esquema do Cenário: Guia de limites
  Dado o README de um pacote Kortex
  Quando o desenvolvedor procura orientação de uso
  Então encontra <conteudo>

  Exemplos:
    | pacote         | conteudo |
    | kortex         | quando usar Signal/Computed/Effect/Resource/Command; quando NÃO usar |
    | kortex_forms   | regra de domínio fora do form; validação vs negócio |
    | kortex_persist | não é sync engine/ORM; contratos de storage/erro |
    | kortex_lib     | toolkit opinativo; importar submódulos; critérios de peso |
```

---

## 5. Ordem sugerida de execução

1. **UC-10.01, UC-10.02, UC-10.03, UC-10.04** — riscos/bugs/segurança primeiro (base confiável).
2. **UC-10.05** — fronteira de API antes de ampliar superfície.
3. **UC-10.06, UC-10.07** — DX e detecção precoce.
4. **UC-10.08** — consolidar documentação após contratos estabilizados.

## 6. Riscos e dependências

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Mudança breaking em `reset`/persist/crypto | Migração de consumidores | SemVer, CHANGELOG, guia de migração, deprecação quando possível |
| Observabilidade virar overhead | Ruído/perf em debug | Opt-in, `kDebugMode`, custo zero em release |
| `kortex_lib` crescer sem critério | Acoplamento/peso | Política de deps e critério de split por eixo |
| Lint ruidoso | Adoção baixa | Regras de alto sinal, severidade calibrada, quick fixes seguros |
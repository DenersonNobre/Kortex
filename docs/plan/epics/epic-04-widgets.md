# Épico 04: Widgets Reativos, Pontes SDK & Exemplo (`EPIC04`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC04` |
| **Dependências Diretas** | `EPIC02`, `EPIC03` |
| **Prioridade** | Alta (Camada de UI & Entrega Final v0.1.0) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Pendente` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Implementar `lib/src/widgets/`, o barrel público `lib/kortex.dart` e o app de exemplo funcional em `example/`, validando a experiência `StatelessWidget`-first e as pontes com `ValueListenable<T>` e `Listenable`.

- **Incluso**: `IKortexPage<TController>`, `KortexWatch`, `KortexSelector<T>`, `KortexListener<T>`, `KortexResourceBuilder<T>`, `KortexListenableAdapter` (`toKortexSignal`, `toKortexSignalWith`, `toListenable`), `lib/kortex.dart` e `example/`.
- **Não Incluso / Fora do Escopo**: roteador próprio ou dependências externas (`RNF-01`).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-04.01** | `IKortexPage`, `KortexWatch` (`child`) e `KortexSelector<T>` | Nenhuma | `Concluído` |
| **UC-04.02** | `KortexListener<T>`, `KortexResourceBuilder<T>` e `KortexListenableAdapter` | `UC-04.01` | `Concluído` |
| **UC-04.03** | Barrel `lib/kortex.dart` e app de exemplo em `example/` | `UC-04.02` | `Concluído` |
| **UC-04.04** | Pipeline CI remota (Gitea + GitHub) e release `v0.1.0` | `UC-04.03` | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] Todos os widgets e pontes cobertos por testes de widget em `test/`.
- [x] `lib/kortex.dart` ocultando coordenadores internos (`KortexTracker`).
- [x] `example/` compilando e analisando sem warnings sob `flutter analyze`.
- [x] Suíte completa (`flutter analyze` + `flutter test`) verde.
- [ ] Pipeline CI remota verde em runner limpo a cada push/PR em `main`, nas duas plataformas: Gitea Actions (`.gitea/workflows/ci.yml`, runner self-hosted) e GitHub Actions (`.github/workflows/ci.yml`).
- [ ] Release `v0.1.0` tagueada com `CHANGELOG.md` promovido e `pubspec.yaml` alinhado (`0.1.0`).

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-04.01 — `IKortexPage`, `KortexWatch` e `KortexSelector<T>`

- **Identificador**: `UC-04.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter
- **Eu quero** escrever páginas `StatelessWidget` via `IKortexPage<TController>` com reconstrução granular via `KortexWatch` e `KortexSelector`
- **Para que** apenas os trechos ligados aos sinais alterados sejam reconstruídos

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Rebuild granular em KortexWatch e KortexSelector
  Dado uma IKortexPage montada com <widget>
  Quando um sinal não selecionado ou selecionado muda para <valor>
  Então a contagem de rebuilds é <rebuilds>

  Exemplos:
    | widget | valor | rebuilds |
    | KortexWatch com child estático | sinal observado muda | reconstrói builder preservando instância do child |
    | KortexSelector observando user.name | user.age muda (name igual) | 0 rebuilds |
    | KortexWatch desmontado | sinal alterado após unmount | 0 chamadas a setState (!mounted) |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-04.01` | `NFR-04` | `setState` após `!mounted` | `0` | `flutter test` |

---

### Caso de Uso UC-04.02 — `KortexListener<T>`, `KortexResourceBuilder<T>` e Pontes `Listenable`

- **Identificador**: `UC-04.02`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter
- **Eu quero** disparar efeitos imperativos seguros com `KortexListener<T>`, renderizar `KortexResource` via `KortexResourceBuilder<T>` e integrar `ValueListenable`/`ChangeNotifier`
- **Para que** `SnackBar`, navegação, formulários e `refreshListenable` funcionem sem acoplamento

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: KortexListener, KortexResourceBuilder e KortexListenableAdapter
  Dado um widget conectado via <componente>
  Quando ocorre <evento>
  Então o resultado observado é <resultado>

  Exemplos:
    | componente | evento | resultado |
    | KortexListener(fireImmediately: false) | montagem inicial | watch descoberto; listener não dispara na montagem |
    | KortexResourceBuilder | Loading(previousValue) -> Data -> Error | renderiza estado correspondente via switch exaustivo |
    | TextEditingController.toKortexSignal() | dispose() do adapter | remove listener mantendo controller utilizável |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-04.02` | `NFR-04` | Listeners residuais após `dispose()` | `0` | `flutter test` |

---

### Caso de Uso UC-04.03 — Barrel Público `lib/kortex.dart` e `example/`

- **Identificador**: `UC-04.03`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** usuário do pacote `kortex`
- **Eu quero** importar apenas `package:kortex/kortex.dart` e consultar um exemplo funcional mínimo
- **Para que** eu tenha a API pública completa e um guia prático de uso sem dependências externas

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Exportação pública e exemplo mínimo
  Dado o barrel lib/kortex.dart e o app em <caminho>
  Quando executamos <verificacao>
  Então o resultado é <status>

  Exemplos:
    | caminho | verificacao | status |
    | lib/kortex.dart | import em test/ e example/ | expõe API pública sem KortexTracker |
    | example/ | flutter analyze | No issues found! |
    | raiz | flutter test | 100% verde |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-04.03` | `NFR-01` | Dependências externas no pacote e `example/` | `0` | Inspeção `pubspec.yaml` |

---

### Caso de Uso UC-04.04 — Pipeline CI Remota (Gitea + GitHub) e Release `v0.1.0`

- **Identificador**: `UC-04.04`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** mantenedor do pacote `kortex`
- **Eu quero** pipelines remotas (Gitea Actions + GitHub Actions) que rodem `flutter analyze` + `flutter test` a cada push/PR em `main`, e uma release `v0.1.0` tagueada com `CHANGELOG.md` promovido e `pubspec.yaml` alinhado
- **Para que** o "verde" tenha testemunha independente do ambiente local em ambas as plataformas e o versionamento seja rastreável por tag

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: CI remota e promoção da release v0.1.0
  Dado o repositório com <artefato> versionado
  Quando ocorre <evento>
  Então o resultado é <status>

  Exemplos:
    | artefato | evento | status |
    | .gitea/workflows/ci.yml | push/PR em main (Gitea) | analyze + test executados em runner self-hosted com exit 0 |
    | .github/workflows/ci.yml | push/PR em main (GitHub) | analyze + test executados em runner limpo com exit 0 |
    | pipeline (prova negativa) | teste quebrado em branch de PR | pipeline reprova (exit != 0), sem merge |
    | pubspec.yaml + CHANGELOG.md | tag v0.1.0 | version: 0.1.0 e [Não publicado] promovido para seção datada |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-04.04` | `NFR-02` | `flutter analyze` nos runners limpos (Gitea + GitHub) | `0 warnings / 0 erros` | Logs dos workflows |
| `UC-04.04` | — | Prova negativa da pipeline versionada | PR com teste quebrado reprova | Execução do workflow |

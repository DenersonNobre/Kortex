# Épico 03: Escopo & Ciclo de Vida na Árvore (`EPIC03`)

## Metadados

| Atributo | Valor |
| --- | --- |
| **Identificador** | `EPIC03` |
| **Dependências Diretas** | `EPIC01` |
| **Prioridade** | Crítica (Injeção Escopada & Anti-GetX) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Pendente` |
| **Referência da SPEC** | [SPEC.md](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Implementar `lib/src/scope/` com provisão explícita na árvore de widgets (`KortexProvider`, `KortexScope`, `IKortexScopeReader` e extensões em `BuildContext`), suportando `lazy`, `.value`, resolução entre irmãos com detecção de ciclos, `overrides` para testes e `KortexScope.capture` para `Overlay`.

- **Incluso**: `IKortexScopeReader`, `KortexProvider<T>` (`eager`, `lazy`, `.value`), `KortexScope`, `KortexScope.capture`, `resolveKortexDependency<T>` e `readKortex<T>()` / `watchKortex<T>()`.
- **Não Incluso / Fora do Escopo**: Service Locator global estático (`INV-06`) e widgets reativos (`EPIC04`).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| --- | --- | --- | --- |
| **UC-03.01** | `KortexProvider`, `IKortexScopeReader` e `KortexScope` (irmãos, ciclo, `lazy`, `dispose`) | Nenhuma | `Concluído` |
| **UC-03.02** | `KortexScope.capture`, `overrides` e `BuildContext` extensions | `UC-03.01` | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] `UC-03.01` e `UC-03.02` cobertos por testes de widget (`flutter_test`).
- [ ] Preservação de instâncias em rebuilds do widget pai verificada por teste.
- [ ] `flutter analyze` e `flutter test` verdes.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-03.01 — `KortexProvider`, Irmãos, Detecção de Ciclo & `lazy`

- **Identificador**: `UC-03.01`
- **Status**: `Concluído`

#### Narrativa (User Story)

- **Como** desenvolvedor de feature modular
- **Eu quero** registrar dependências eager/lazy em `KortexScope` com resolução entre irmãos e descarte automático
- **Para que** serviços sejam criados sob demanda, ciclos falhem rápido e tudo seja descartado em LIFO ao desmontar

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Criação, resolução entre irmãos, ciclo e descarte em KortexScope
  Dado um KortexScope configurado com <configuracao>
  Quando ocorre <evento>
  Então o resultado esperado é <resultado>

  Exemplos:
    | configuracao | evento | resultado |
    | Provider A depende de B (lazy: true) | readKortex<A>() | instancia B e depois A |
    | Provider A <-> B circular | montar KortexScope | lança StateError indicando ciclo |
    | Provider .value + Provider IKortexDisposable | desmontar KortexScope | descarta apenas IKortexDisposable (preserva .value) |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-03.01` | `INV-07` | Ciclos detectados sem `StackOverflowError` | `100%` | `flutter test` |

---

### Caso de Uso UC-03.02 — `KortexScope.capture`, `overrides` e `BuildContext` Extensions

- **Identificador**: `UC-03.02`
- **Status**: `Pendente`

#### Narrativa (User Story)

- **Como** desenvolvedor Flutter
- **Eu quero** usar `readKortex`/`watchKortex`, `overrides` em testes e `KortexScope.capture` em `showDialog`
- **Para que** modais no `Overlay` acessem o escopo da tela e testes substituam dependências reais por fakes

#### Critérios de Aceitação (Gherkin Executável)

```gherkin
Esquema do Cenário: Resolução em árvore, capture em Overlay e overrides
  Dado uma árvore de widgets com <cenario>
  Quando o widget filho chama <operacao>
  Então o comportamento observado é <resultado>

  Exemplos:
    | cenario | operacao | resultado |
    | KortexScope com overrides=[FakeRepo] | context.readKortex<Repo>() | retorna FakeRepo |
    | showDialog envolvido com KortexScope.capture | readKortex<Ctrl>() no dialog | retorna Ctrl e não o descarta ao fechar dialog |
    | árvore sem KortexScope ancestral | context.readKortex<Ctrl>() | lança StateError indicando Ctrl ausente |
```

#### NFRs Mensuráveis

| UC | NFR | Métrica | Target | Medição |
| --- | --- | --- | --- | --- |
| `UC-03.02` | `INV-03` | Tipo ausente lança `StateError` explícito | `100%` | `flutter test` |

# Proposta: Split da `kortex_lib` — `kortex_core`, `kortex_rest`, `kortex_sqlite` + barrel

## 1. Objetivo & Posicionamento

A `kortex_lib` atual declara `crypto` + `encrypt` + `http` + `sqflite` para todos os consumidores, embora cada dependência sirva a um único eixo (`encrypt`→`core/security`, `http`→`rest/`, `sqflite`→`sqlite/`). Quem só usa `Result`/`Money` resolve plugin de plataforma no grafo. Barrel seletivo não salva: dependência no pub é por pacote.

- **Incluso**: extração de `kortex_rest` e `kortex_sqlite`; criação de `kortex_core` (kernel atual); `kortex_lib` como guarda-chuva fino (só re-export); migração de `poc/` + docs.
- **Não Incluso**: fatiar o `core/` internamente (Result/patterns/logging/models ficam juntos — acoplamento legítimo, custo de N pacotes supera o benefício); renomear pacotes já publicados além do estritamente necessário.

---

## 2. Desenho (decidido com o PO)

| Pacote | Conteúdo | Deps |
| --- | --- | --- |
| `kortex_core` | `core/` atual (Result, Money, patterns, logging, security, services, helpers) | `crypto`, `encrypt` (+ `kortex`, `kortex_forms` onde já houver) |
| `kortex_rest` | `rest/` atual (client, retry, middleware, datasources) | `http` (+ `kortex_core`) |
| `kortex_sqlite` | `sqlite/` atual (provider, migrations) | `sqflite` (+ `kortex_core`); modelo: `kortex_persist` (porta + adapters, não ORM) |
| `kortex_lib` | **Só barrel**: re-exporta os três. Opt-in explícito, com custo declarado no README ("atalho com peso: puxa o grafo cheio") | os três |

**Decisões registradas**:
- Barrel é **conveniência opt-in**, não porta de entrada: READMEs, `example/`s e `poc/` usam import seletivo; o barrel existe para quem escolhe o custo.
- Migração do kernel sem breaking: `kortex_lib` re-exportando `kortex_core` mantém imports existentes compilando. Sem ciclo `@Deprecated` obrigatório — mas a doc empurra o import direto (risco aceito: dualidade temporária na cabeça dos consumidores).
- `rest/`: decidir no fatiamento se vira client opinativo ou só helpers (muda o tamanho do pacote).

---

## 3. Governança & Gate de Entrada

1. **Quando criar**: após a EPIC12 estar em curso com o lar dos widgets estabilizado (evita mover `widgets/` duas vezes — já migrados uma vez na EPIC11); sem pressa artificial, é dívida de peso, não bug.
2. **Regra "exemplos usam import seletivo"**: nenhum `example/`, teste ou doc nova pode importar o barrel quando o import direto basta (gate: grep no CI ou checklist de review).
3. **Cada pacote novo** exige `example/`, `topics:`, README com "quando usar/quando NÃO usar", CHANGELOG e suíte própria — custo declarado, não escondido.
4. **`@Deprecated` de verdade** onde houver símbolo movido com consumidor provável (`rest`/`sqlite` têm — ao contrário da EPIC11, aqui a remoção silenciosa quebraria sem aviso).

---

## 4. Contrato técnico de execução (lições da EPIC10/EPIC11 — não negociar)

1. **Mover = mover código + testes + docs juntos**: a EPIC11 perdeu ~12 arquivos de teste na remoção (só recuperados depois, por sorte passarem de primeira). O commit que remove da origem deve conter o port no destino; suíte do pacote novo com contagem **maior ou igual** à origem, nunca menor sem justificativa.
2. **Gherkin ↔ código, paridade total**: mesma regra da proposta irmã — sem linha órfã, sem diferimento silencioso.
3. **Prova de não-regressão do barrel**: teste (ou gate) que importa **só** pelo barrel e exercita um símbolo de cada pacote re-exportado — se um export quebrar, o teste quebra. Barrel sem teste é declaração, não contrato.
4. **Peso auditável**: teste/gate que lista as dependências resolvidas de cada pacote novo (`flutter pub deps`) e falha se `kortex_core` puxar `http`/`sqflite` ou se `kortex_rest` puxar `sqflite`. É o enforcement da UC-10.05 que ficou só no texto.
5. **Sem duplicação residual**: após a extração, grep por símbolos movidos na `kortex_lib` deve retornar zero (fora dos re-exports intencionais). Duplicação viva reprova.
6. **Diff Budget e status**: 1 pacote extraído = 1 UC (código + testes + example + CHANGELOGs origem/destino). Seções do épico só `Concluído` com evidência; DoD marcada com comando + saída, nunca por afirmação.

---

## 5. Parecer Técnico (Revisão)

1. **`kortex_core` vs `kortex_lib` durante a transição**: enquanto `kortex_core`, `kortex_rest` e `kortex_sqlite` não forem publicados no `pub.dev`, `example/`s que os referenciem não devem ter `pubspec.yaml` próprio fora do workspace (lição da `EPIC11`), para não falhar no `flutter pub get`.
2. **`kortex_rest` (decisão da §2)**: preferir **helpers + cliente HTTP fino** sobre `http.Client` (retry, timeout, middleware) em vez de framework opinativo de API, mantendo o pacote leve e fácil de mockar com `MockClient`.
3. **`kortex_sqlite`**: seguir o mesmo padrão de porta + adapter de `kortex_persist` (`IKortexDatabase` / migrations versionadas), permitindo testar repositórios em memória sem subir SQLite nativo em testes unitários.
4. **Gate de peso (§4.4)**: automatizar em teste Dart (`Process.run('dart', ['pub', 'deps', '--json'])` ou leitura de `pubspec.lock` / `pubspec.yaml`) para falhar no CI se `kortex_core` puxar `http`/`sqflite`.

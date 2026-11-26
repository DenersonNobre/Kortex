# Aprendizados — kortex

> Transversais promovidos para os canônicos do Oráculo (regra de ouro):
> `topics/flutter.md` (Puro sem 7z, Flutter 3.50 × zero-deps, limite do barrel com ponto),
> `topics/git-multiagent.md` (`assume-unchanged` esconde deleção),
> `topics/devops-docker.md` (`container.network` inexistente mata jobs em 2s).
> Detalhe de implementação desta sessão: entradas datadas abaixo.

## 2026-11-23 — `dart format` no CI antes do `pub get` falha ao resolver `analysis_options.yaml`

- **Sintoma:** o workflow do GitHub Actions (`45099719485`) falhou no step `Format check` com `Failed to resolve package URI "package:flutter_lints/flutter.yaml"`.
- **Causa:** `dart format` lê `analysis_options.yaml` de cada pacote, mas rodava **antes** de `flutter pub get` gerar `.dart_tool/package_config.json`.
- **Fix:** mover `flutter pub get` na raiz do workspace para **antes** do `dart format --output=none --set-exit-if-changed`.

## 2026-11-23 — `example/` fora do workspace não pode misturar `path:` e `hosted` para o mesmo pacote

- **Sintoma:** `flutter pub get` em `packages/kortex_persist/example/` falhou com `version solving failed` (`kortex_persist from path is forbidden`).
- **Causa:** `kortex_persist` dependia de `kortex: ^0.2.2` (hosted), enquanto `example/` declarava `kortex: path: ../../kortex_state`.
- **Fix:** manter `kortex: ^0.2.2` (hosted) no `example/pubspec.yaml` quando o exemplo está fora do `workspace:` raiz.

## 2026-11-20 — `LeakTesting` do `flutter_test` NÃO enxerga controller que não é `ChangeNotifier`

- **Sintoma:** a suíte da POC rodava 103 testes verdes e nenhum deles verificava vazamento. O pacote tinha gate (`test/flutter_test_config.dart` + prova negativa), a POC não.
- **Causa (a parte que engana):** ligar `LeakTesting.enable()` **não** cobre o risco real deste projeto. `IKortexController` implementa `IKortexDisposable`, **não** estende `ChangeNotifier` — e o leak tracker do Flutter só conhece objetos que despacham `dispatchObjectCreated/Disposed` (framework). Controller nosso esquecido é invisível para ele; o gate ficaria verde com a capacidade morta.
- **Fix (duas camadas):** (1) `LeakTesting.enable()` na config para objetos do framework; (2) gate de ciclo de vida próprio — `track(controller)` + `tearDown` chamando `assertAllDisposed` sobre `isDisposed`, que é estado real do controller (não inventário).
- **Prova negativa dos dois lados:** teste sintético (controller vivo reprova / descartado aprova) **e** mutação em teste real (`controller.dispose()` removido) reprovando o próprio teste que vazou. Sem a mutação, o gate seria só declaração.
- **Corolário:** em qualquer biblioteca que ofereça ciclo de vida próprio (`dispose`), "ativar leak tracking" não é suficiente — a classe precisa expor estado de descarte (`isDisposed`) para o gate conseguir julgar. Se não expõe, o primeiro passo é expor.

## 2026-11-20 — Agregado de apoio que é o próprio usuário não deve virar entidade

- **Sintoma de projeto:** a POC modelava `Technician` como agregado (cadastro + dropdown no formulário). O dono do produto apontou que, num app de campo, **o técnico é quem está usando o app** — o cadastro era um modelo de despacho/back-office que ninguém pediu.
- **Causa:** confundir "papel no negócio" com "agregado persistido". O técnico é **identidade de sessão**, não um registro a ser escolhido; escolher a si mesmo no formulário não faz sentido.
- **Fix:** módulo `session` com `SessionUser` (nome + especialidade) e porta `ISessionProvider`; `Visit.technicianName` guarda o nome como **snapshot** (histórico não muda se o usuário mudar de nome); o agregado `Technician` foi removido. Em produção a identidade vem do servidor — o cliente nunca é fonte de autorização de papel.
- **Prevenção:** antes de criar agregado para uma pessoa do domínio, perguntar "ela escolhe o próprio nome numa lista?". Se a resposta é não, é sessão, não entidade.

## 2026-11-20 — Fronteira de bounded context se mede por onde o dado mora, não pela tela que o mostra

- **Sintoma:** `Client` morava em `modules/visits/domain/` e o cadastro estava na fachada de **visitas** — a tela de Clientes consumia a fachada de outro contexto só porque foi a primeira a existir.
- **Causa:** o agregado nasceu como dependência de `Visit` e nunca foi promovido quando ganhou tela e commands próprios.
- **Fix:** `modules/clients/{domain,data,commands,features}` com `ClientUseCases`; `visits` depende só da **porta** (`ClientRepository`) para validar e resolver nome no join; `VisitsController` perdeu `createClient` (virou código morto da tela antiga).
- **Prevenção:** quando um conceito ganha tela, commands e ciclo de vida próprios, ele deixa de ser detalhe de outro contexto — mover no mesmo commit, não "depois". Código morto de tela antiga (`createClient` no controller de visitas) é o sintoma de que a fronteira ficou para trás.

## 2026-11-20 — Providers inline em `StatelessWidget` recriam o escopo a cada build

- **Sintoma:** ao cadastrar um cliente e voltar para a lista, o item **sumia**; e trocar de aba zerava as listas. Comprovado por print: o controller consultado tinha `[Empresa Nova]`, mas a tela mostrava 0 tiles.
- **Causa:** o escopo por area (`ClientsScope`) era `StatelessWidget` e construia `KortexScope(providers: [KortexProvider(...)])` **dentro do `build`** — lista nova a cada rebuild, e o `KortexScope` compara providers por **identidade**: lista diferente ⇒ descarta tudo e recria o controller. O controller que a tela lia nao era o mesmo que recebeu o dado.
- **Fix:** escopo por area virou `StatefulWidget` com a lista de providers criada **uma vez** em `didChangeDependencies` (`_providers ??= [...]`).
- **Prevencao:** em `KortexScope`, providers devem ser `const`/estaveis; se dependerem de `context`, crie-os uma vez num `State`. Teste de regressao cobre navegacao entre areas preservando o estado.

## 2026-11-20 — Seed de dados pertence ao store, nao a tela

- **Sintoma:** o cliente de demonstracao nao aparecia na area de Clientes (lista vazia) porque o seed rodava no controller de Visitas e a lista de Clientes ja havia carregado antes.
- **Causa:** ordem assincrona entre duas areas — sem vinculo reativo entre elas, o dado criado depois nao aparecia.
- **Fix:** `InMemoryClientStore/InMemoryTechnicianStore(seedDemo: true)` semeiam no construtor (o "open" do banco), de forma sincrona — nenhuma tela depende da ordem de carga da outra.
- **Prevencao:** dado inicial e responsabilidade da camada de dados/migration, nunca de um controller de tela.

## 2026-11-20 — Filtro "pula" ao selecionar: duas causas medidas (chip e Column)

- **Sintoma (relatado na UI):** ao clicar numa opção do filtro, ela "centraliza e volta para a esquerda".
- **Causa 1 — `ChoiceChip` cresce ao selecionar:** ele exibe `checkmark` por padrao; medido, o chip ia de **160,9 px para 180,9 px** e o layout refluia. Fix: `showCheckmark: false` (largura estavel).
- **Causa 2 — linha centralizada durante o `Loading`:** o `Column` usa `crossAxisAlignment.center` por padrao e, com o corpo em spinner, nada forcava a largura — a linha de filtros **encolhia e centralizava** (x=50,2) e voltava para a esquerda (x=0) quando os dados chegavam. Fix: `crossAxisAlignment: CrossAxisAlignment.stretch` no `Column`.
- **Prova e prevencao:** teste de regressao mede `tester.getRect(chip)` em varios frames da troca de filtro e exige retangulo identico — o bug e' de layout, entao a assercao e' geometrica, nunca "olhar a tela".

## 2026-11-20 — `Navigator.pop` assíncrono: a rota só some no frame seguinte

- **Sintoma:** o dialog de nova visita não fechava no teste mesmo com `pop()` comprovadamente chamado (`print` mostrou `canPop=true` e a chamada executada) — e o dado tinha sido salvo.
- **Causa:** o `pop()` acontecia **depois** do último frame (a ação é `async` e resolve em microtask); a remoção da rota só se materializa no frame seguinte, e o teste assertava logo após um `pump` único.
- **Fix:** fechar com `await tester.pumpAndSettle()` (ou um `pump` extra) após a ação assíncrona — nunca `expect` imediatamente após o `pump` que consumiu o `await`.

## 2026-11-20 — Latência simulada encadeada: medir antes de fixar o `pump`

- **Sintoma:** teste de widget falhava com a lista ainda em `KortexAsyncLoading` após `pump(400ms)`, embora cada store tivesse 200ms.
- **Causa:** a carga encadeia **dois** acessos sequenciais (`listClients` então `listTechnicians`) = ~400ms, e o `pump` de 400ms caiu exatamente na borda (microtask após o último frame).
- **Prevenção:** com latência simulada, medir a cadeia (n × latência) e usar folga (`pump(2s)` ou `pumpAndSettle`); o teste unitário correspondente usa `Duration.zero` para não pagar o custo.

## 2026-11-20 — `flutter test` ignora vazamentos por padrão: `LeakTesting.enable()` e o contrato do config

- **Sintoma:** um `ValueNotifier` deliberadamente não descartado **passou** no `flutter test` — o gate de leak não reprovava nada. Ligando o tracking, apareceram 3 vazamentos: 1 real do pacote (`_KortexScopeState` + `StatefulElement` vivos quando `create` lança `StateError` em `initState`), 1 do teste (`ChangeNotifier` sem dispose) e 1 do probe.
- **Causa (medida no SDK):** `leak_tracker_flutter_testing` sobe com `LeakTracking.phase = const PhaseSettings.ignored()` — **vazamentos são ignorados por padrão**; o reporter padrão (`expect(leaks, isLeakFree)`) só reprova com o tracking ligado.
- **Contrato do `flutter_test_config.dart` (erro próprio, medido):** o `flutter_tools` chama `test_config.testExecutable(<main do teste>)` — a assinatura correta é `Future<void> testExecutable(FutureOr<void> Function())` **assíncrona e awaiting** o main. Sem o `await`, o runner encerra antes dos testes se registrarem ("No tests were found"); com assinatura síncrona, o runner nem compila (`Method not found: 'testExecutable'`).
- **Fix do pacote:** criação eager do `KortexScope` saiu do `initState` para o primeiro `build` — assim o element monta e o framework descarta o `State` normalmente (o `StateError` continua reportado e capturado por `takeException`).
- **Prevenção:** `test/flutter_test_config.dart` versionado liga o gate para toda a suíte, e `kortex_leak_gate_test.dart` é a prova negativa (cria objeto rastreado e não descartado, afirma que o tracker acha e que `isLeakFree` reprovaria).

## 2026-11-20 — `is` com early-return NÃO promove união selada genérica

- **Sintoma:** `if (x is Fail<T>) return ...; x.value` não compilou (`The getter 'value' isn't defined for type 'Result<T>'`) — provado em isolamento com `sealed` mínima + em `Category.draft`/`Task.draft`.
- **Causa (verificada, não suposição):** a negação do `is` não subtrai o ramo testado quando há parâmetro de tipo envolvido, mesmo com a hierarquia selada completa no mesmo arquivo.
- **Fix/padrão da casa:** `as Ok<T>` explícito após o guard; alternativa idiomática é `switch` com pattern (`case Ok(value: final v)`), que destrutura com segurança. Candidato a `topics/flutter.md` quando houver fluxo de claim.

## 2026-11-20 — Campo novo em entidade exige grep em todos os pontos de (re)construção

- **Sintoma:** `categoryId` sumiu na persistência: 2 testes falharam (`deleteCategory` liberou categoria em uso; `listByCategory` voltou vazio) — causa única no `_insert` do adapter, que reconstruía `Task` sem o campo novo.
- **Causa:** o campo foi adicionado à entidade e ao construtor, mas o adapter tem seu próprio ponto de construção (`Task(...)` explícito) que o compilador não acusou (todos os campos têm default).
- **Prevenção:** ao adicionar campo com default, grepar `Task(` no repo inteiro — construtor nomeado com defaults nunca quebra sozinho, e o teste que cobre o join (`listByCategory` com nome resolvido) é o que denuncia.

## 2026-11-19 — Barrel com ponto (`.reactive.dart`) não embarca no pub.dev

- **Sintoma:** `dart pub publish --dry-run` listou `kortex_*.dart` mas omitiu `.reactive.dart` do arquivo a publicar — o barrel funcionava local/git/CI e sumiria para consumidores do pacote.
- **Causa:** o empacotador do pub ignora dotfiles ao montar o archive; nada no `flutter analyze` ou `flutter test` acusa (15/15 verdes com o ponto).
- **Prevenção:** todo barrel novo passa por `dart pub publish --dry-run | Select-String <arquivo>` antes da release (prova incluída na `UC-04.04`); barrels publicados nunca usam prefixo `.`.

## 2026-11-19 — `KortexComputed` observado recomputa na hora; sem observador, só dirty
- **Sintoma:** `KortexComputed` avisava a jusante ao invalidar e só recomputava na leitura — derivado igual gerava notificação fantasma (teste `só notifica quando o derivado muda` falhou com 1 aviso onde esperava 0).
- **Causa:** notificação ansiosa antes da comparação por `equals`; a SPEC pede invalidação em cascata, mas o `equals` do construtor só faz sentido se gatear o aviso.
- **Fix:** sem observadores, só `_isDirty = true` (lazy); com observadores, `_recompute()` imediato e aviso só se o derivado mudou (`_storeIfChanged`). `KortexSelector` continua como filtro de rebuild na UI.


## 2026-11-19 — Ponte `toStream` estourou a pilha por assinar via tracker

- **Sintoma:** `toStream` com `runWithObserver` na anexação entrou em recursão infinita (`Stack Overflow`): `recordRead` chama `onRead` já na coleta, e a ponte lia+emitia de novo a cada aviso.
- **Causa:** `onRead` serve a dois momentos (coleta vs. notificação); `Computed`/`Effect` distinguem com `_isCollecting`, mas ponte folha não precisa de coleta.
- **Fix:** `_SignalStream._attach` assina direto via `node.addObserver(bridge)` — sem moldura de tracker; `onRead` passa a disparar só em mudança real, e o `cancel` remove o observador.

## 2026-11-20 — CI dupla provada: verde 2× e vermelha no teste sabotado

- **Sintoma:** `flutter analyze` local verde, CI vermelha — e runner Gitea matando jobs em 2s (`network gateway_net not found`).
- **Causa (3×):** (1) rede do runner apontava para `gateway_net` inexistente (fix: `gitlan_net` + restart, com flag de assar na imagem); (2) Flutter 3.50.0 deprecia `material.dart` e `analyze` sai != 0 até para `info` — migração quebraria o RNF-01, então pin 3.47.6; (3) prova negativa 2 falhou no *format* (arquivo não formatado), não no *test*.
- **Prova final:** GitHub — main verde 2× (`44670837671`, `44671303872`), prova 3 vermelha no step Test (`80 passed, 1 failed`, run `44671612004`); Gitea — pipeline completa no runner corrigido, `No issues found!`, vermelha no sabotado (run 66). Prova 2 (`44670894144`) valeu pelo gate de formato.
- **Prevenção:** pin de toolchain documentado nos workflows; prova negativa futura deve passar no format local antes do push.

## 2026-11-20 — CI pinada na 3.47.6: 3.50.0 deprecia `material.dart`

- **Sintoma:** CI verde local (env padrão 3.47.6) e vermelha no GitHub com 7 infos `deprecated_member_use` pedindo `package:material_ui` — que não existe no SDK (só como pacote externo).
- **Causa:** `flutter analyze` sai com exit != 0 para qualquer nível, inclusive `info`; migrar quebraria o RNF-01 (zero dependências externas).
- **Fix:** workflows pinados na 3.47.6 (última sem a depreciação; mesma de todos os verdes locais). Revisitar quando o RNF-01 permitir ou o `material_ui` vier no SDK.

## 2026-11-20 — Testes async de widget: aguardar o `Future`, não o `pump`

- **Sintoma:** 3 testes quebraram sem defeito na lib: `complete()` + 1 `pump()` não garantia a continuação do `Future`; `showSnackBar` insere overlay que só constrói no frame seguinte; `TextEditingController.value` tipa `TextEditingValue`, não `String`.
- **Causa:** `pump()` não ordena microtasks do `Future` do recurso; overlay precisa de frame extra; tipo do `ValueListenable` é o do `value`, não o do texto.
- **Fix:** aguardar o `Future` do `refresh()` antes do `pump` (determinístico); `pump` duplo pós-`showSnackBar`; separar teste `ValueNotifier<String>` (fluxo) de `TextEditingController` (posse pós-dispose).

## 2026-11-20 — `KortexSelector` compõe `Computed` + `Watch` em vez de observar direto

- **Sintoma:** seletor precisava de coleta de deps, comparação por `equals`, agenda fora de fase e ciclo de vida — tudo já testado em `KortexComputed`/`KortexWatch`.
- **Causa:** reimplementar duplicaria a máquina de invalidação (e os seus bugs).
- **Fix:** `_KortexSelectorState` guarda só o `KortexComputed` (com o `equals` do widget) e o `build` retorna um `KortexWatch` interno que lê o derivado; `didUpdateWidget` recria o derivado e o rebuild do pai reassina o `Watch` interno.

## 2026-11-19 — `capture` precisa de token de tipo explícito

- **Sintoma:** `KortexScope.capture` montava providers `KortexProvider<dynamic>.value` cujo `type` resolvia `dynamic` — leitura no dialog lançava `StateError` de provider ausente mesmo com a instância coletada.
- **Causa:** o mapa do escopo é chaveado pelo `type` do provider; genérico apagado (`dynamic`) nunca casa com `T` na resolução, e o `as KortexProvider<T>` ainda quebraria o cast.
- **Fix:** `_CapturedProvider` privado carrega o `Type` coletado junto do valor; `_materialize` sem cast de provider (só `as T` no valor, com cheque real em runtime).

## 2026-11-19 — Um provider por `Type`: duplicata colide, não ordena

- **Sintoma:** teste de LIFO com dois providers do mesmo `Type` descartou só um (`['b']` em vez de `['b','a']`) — o mapa `_effective`/`_instances` usa `Type` como chave e o segundo registro sobrescreveu o primeiro.
- **Causa:** escopo resolve por tipo; dois providers do mesmo tipo na mesma lista é erro de configuração, não fila.
- **Fix:** teste usa tipos distintos (`TaggedDisposable<ServiceA>` vs `<ServiceB>`); semântica documentada — um `Type`, um provider por escopo (o `overrides` da `UC-03.02` substitui, nunca duplica).

> Aprendizados específicos DESTE repositório (arquitetura, decisões, gotchas do projeto). (arquitetura, decisões, gotchas do projeto).
> Os transversais (qualquer projeto da mesma stack) sobem para `agents/rules/topics/<stack>.md`
> ou `agents/rules/global_learnings.md`; procedimento reutilizável vira Skill.
> Antes de deixar algo só aqui, teste: **"valeria se eu clonasse outro projeto de tecnologia
> idêntica?"** — sim → promove; não → fica. Nunca nomear projeto/cliente/tabela de outro
> contexto nos canônicos; aqui o contexto local é permitido e desejado.

## 2026-11-19 — Decisões de desenho pré-código na SPEC do Kortex

- **Sintoma:** Na revisão da `SPEC.md`, `KortexListener` com apenas `listener(context)` não conseguia descobrir sinais com `fireImmediately: false` sem disparar o efeito colateral no `initState`; além disso, `Listenable.toKortexSignal` colidia com `ValueListenable<T>.toKortexSignal()` por subtipagem em Dart.
- **Causa:** Misturar leitura reativa pura com efeito colateral na mesma closure impede descoberta segura de dependências na montagem; e extensões com o mesmo nome em `Listenable` e `ValueListenable<T>` geram ambiguidade estática no Dart.
- **Prevenção:** Manter `watch` separado de `listener` em `KortexListener<T>` (`docs/architecture/SPEC.md`) e usar nomes distintos (`ValueListenable<T>.toKortexSignal()` vs `Listenable.toKortexSignalWith<T>(read)`).

## Regras (não apagar ao instanciar)

1. Uma seção `## AAAA-MM-DD — <título>` por aprendizado, na mesma unidade de trabalho do fix.
2. Entrada sem sintoma medido é hipótese — marque como tal até ter evidência.
3. Ao remover código com entradas aqui, **generalizar o contexto** em vez de deletar
   (ex.: nome de app específico → "app Delphi com res em fresh clone").
4. Promoção: reutilizado em 2+ lugares → global; virou workflow → propor Skill.

## 2026-11-24 — POC: `AppResult`, `seedPreview` e `dart format`

- **Não duplicar patterns da `kortex_lib` no `core/` da POC**: nunca manter dois `Result` equivalentes nem enfraquecer a assinatura genérica `IResult<TSuccess, TFailure>` da biblioteca. Usar `typedef AppResult<T> = IResult<T, AppFailure>;` + `extension` em `poc/lib/core/result.dart`.
- **Separar `seedPreview` de `seedDemo`**: manter `seedDemo` mínimo para testes determinísticos (`List.single`, listas vazias) e usar `seedPreview: true` apenas em `poc/lib/main.dart` para visualização prévia rica.
- **`dart format` obrigatório antes do commit**: o CI executa `dart format --output=none --set-exit-if-changed`; rodar `dart format poc/lib poc/test` junto com `flutter analyze` e `flutter test` antes de commitar.

## 2026-11-26 — Auditoria dos pacotes: descarte, persistência e APIs nullable

> Parecer de auditoria + lacunas de evolução. Itens marcados como **[risco/bug]** exigem reprodução/teste antes de fix; itens **[evolução]** são capacidade/DX e devem entrar por épico/UC com DoR/DoD.

### Achados originais (endossados)

- **[risco/bug] Descarte composto precisa terminar todos os cleanups mesmo se um falhar**: `KortexDisposeBag.dispose()` marca o bag como descartado antes de percorrer callbacks; se um callback lança, os posteriores não executam e uma segunda chamada não retoma o trabalho. Testar falhas de callbacks e preservar o erro sem abandonar os demais recursos.
- **[risco/bug] Persistência assíncrona precisa ordenar operações e expor falhas**: `KortexPersistedSignal` dispara `write` sem aguardar; hidratação, mutação e `clear()` podem concorrer, e a API atual não oferece confirmação da escrita. Cobrir essas intercalações com armazenamento controlado por `Completer`.
- **[risco/bug] Parâmetro `T?` não distingue “omitido” de “valor null”**: `KortexField.reset(nextValue)` usa `nextValue ?? _initialValue`, portanto um campo nullable não pode ser explicitamente resetado para `null`; usar um contrato que represente presença separadamente (sentinela/sealed option).
- **[risco/segurança] `SecretCipher` não deve ser apresentado como proteção de segredos em produção sem cifra autenticada e derivação de chave apropriada**: a implementação atual usa AES-CFB64 e deriva a chave diretamente do segredo com SHA-256 seguido de MD5, sem salt nem autenticação. Mínimo: rotular limite; ideal: AEAD + KDF com salt/custo adequado + nonce/IV correto.
- **[esteira] A verificação de formatação deve usar o SDK do CI**: com Flutter 3.47.6/Dart 3.13.5, o gate atual identifica `kortex_app.dart` e `kortex_app_test.dart` como não formatados.
- **[contrato] Fronteira estrita de API pública (`@internal` + barrels enxutos)**: garantir que detalhes de `src/` não vazem nos exports públicos, mantendo `SemVer` previsível para consumidores. Aplicar em todos os pacotes, com atenção especial ao `kortex_lib`.
- **[evolução] Diagnóstico em `kDebugMode`**: hooks opcionais (sem custo em release) para inspecionar rebuilds de `KortexWatch`, resolução de `KortexScope` e falhas silenciosas em `KortexResource`/`KortexCommand`.
- **[evolução] Guia curto de "quando NÃO usar"**: documentar no `README` de cada pacote onde termina sua responsabilidade (ex.: `ValueNotifier` local de animação não precisa virar `KortexSignal`; regra de domínio não deve ir para `KortexForm`).

### Lacunas acrescentadas (parecer sênior)

- **[evolução][kortex] Observabilidade concreta**: labels debug em primitivas, rastreio opt-in de grafo/ciclo de vida, caminho para `dart:developer`/DevTools, e helpers de teste (matchers de `IKortexAsyncState`, controle de tempo para debounce/throttle). Sem especificação, “diagnóstico em kDebugMode” fica amplo demais.
- **[evolução][kortex] Ergonomia async segura**: `runIfActive`/guard em controller, `KortexCommand.canExecute`, cancelamento/“último vence” com semântica explícita, `KortexEffect.once` e `throttle` onde fizerem sentido.
- **[evolução][kortex_persist] Contrato de durabilidade**: além de ordenar/expor falhas, definir `debounceWrite`/`flush()`, política em erro (`fallback initial` vs rethrow/estado de erro), confirmação de escrita e versionamento/migração de payload (`version`, `migrate`).
- **[evolução][kortex_forms] Além do reset nullable**: validação async com cancelamento/estado `validating`, composição (`FormGroup`/arrays/campos aninhados), `submit`/`touchAll`/`reset` com semântica clara de `dirty/touched`, e bindings Flutter opcionais mantendo o núcleo testável sem `BuildContext`.
- **[evolução][kortex_lint] Quick fixes e regras de alto sinal**: quick fix para `autoDispose`/criação em `build`; regras para side effect em `Computed`, leitura reativa fora de tracking, descarte manual ausente, `autoDispose` em tipo não-disposable; códigos estáveis e mensagens com “por quê + exemplo”.
- **[evolução][kortex_lib] Governança de peso/deps**: política explícita de dependências e critério de split quando um eixo ganhar vida própria (`rest`, `sqlite`, `widgets`, `brlib`). Manter `Result`/erros/utilitários “sharp”, sem duplicar primitivas do `kortex` nem criar state management paralelo.
- **[processo] Prova negativa por achado**: cada item `[risco/bug]` deve entrar com sintoma reproduzido, teste vermelho, fix mínimo, teste verde. Para `DisposeBag`, cobrir callback que lança preservando erro e executando demais callbacks; para `KortexPersistedSignal`, cobrir corrida com `Completer`.

## 2026-11-26 — Mover código entre pacotes sem os testes perde cobertura em silêncio

- **Sintoma:** após extrair os widgets da `kortex_lib` para o `kortex_widgets`, o pacote novo tinha 1 arquivo de teste; os ~12 arquivos de teste dos widgets genéricos ficaram para trás na remoção, e a suíte "verde" (1/1) escondia a regressão.
- **Causa:** o commit de move levou só `lib/`; remoção na origem e port no destino em commits separados, sem checagem de contagem.
- **Fix:** port dedicado (13 arquivos, +69 testes, todos verdes de primeira — o que também validou a fidelidade da migração do código).
- **Prevenção:** commit que remove da origem deve conter o port no destino; contagem de testes do pacote novo ≥ origem, nunca menor sem justificativa (regra registrada nas propostas `kortex_widgets_p2.md` e `kortex_lib_split.md` §4).

## 2026-11-26 — Constraint de SDK divergente entre pacotes do workspace

- **Sintoma:** `kortex_widgets` com `flutter: ">=3.24.0"` enquanto os demais exigem `">=3.47.6"` — promete compatibilidade nunca exercida na matrix do CI (pin 3.47.6).
- **Causa:** escafado por template/valor padrão, sem revisão no review do pacote novo.
- **Fix:** uniformizado para `">=3.47.6"`.
- **Prevenção:** conferir `environment` no review de pacote novo; divergência de piso sem matrix que a prove é dívida, não flexibilidade.

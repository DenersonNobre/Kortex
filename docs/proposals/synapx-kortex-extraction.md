# Proposta: extração segura de ideias do Synapx

## Contexto

O pacote `synapx` foi analisado em:

`A:\Projetos\flutter\.dnolib\lib\synapx`

O Kortex já possui reatividade granular, escopo explícito na árvore de widgets,
ciclo de vida determinístico e política de zero dependências externas. Portanto,
a proposta não é importar `synapx` ou `dnolib`, mas extrair conceitos úteis e
reimplementá-los nos contratos do Kortex.

## Decisão de escopo

Preservar:

- `lib/src/reactive/` como Dart puro;
- APIs públicas com prefixos `IKortex*` e `Kortex*`;
- resolução via `KortexScope` + `BuildContext`;
- descarte explícito e resultados assíncronos tardios descartados;
- ausência de dependências externas em `pubspec.yaml`.

Não transformar o Kortex em framework de roteamento, composição de aplicativo ou
camada Material.

## Matriz de aproveitamento

| Capacidade do Synapx | Decisão | Aplicação no Kortex |
|---|---|---|
| `SynapxCompositeDisposable` | Extrair conceito | O `KortexDisposeBag` já cobre o LIFO; considerar apenas adaptadores de cancelamento se surgir lacuna real. |
| `SynapxController` | Adaptar parcialmente | `IKortexController` já cobre o ciclo básico; avaliar apenas operação assíncrona protegida contra descarte. |
| `SynapxComputed` e tracker por `Zone` | Não copiar | `KortexComputed` e `KortexTracker` já são os contratos canônicos. Aproveitar somente casos de teste de dependência condicional. |
| `SynapxEffect.once` e `interval` | Adaptar sob demanda | Adicionar somente se houver requisito comprovado e com semântica explícita de descarte. |
| `SynapxList` e `SynapxMap` | **Prioridade alta** | Reimplementar coleções reativas nativas do Kortex, com no-op, batch, leitura rastreada e descarte testados. |
| `SynapxModule` e `SynapxModuleScope` | Não duplicar | `KortexProvider` e `KortexScope` já cobrem providers, lazy, hierarquia, overrides, ciclos e ownership. |
| `SynapxTestScope` | Extrair conceito | Criar helpers de teste apenas sobre `KortexScope`, sem segunda resolução de dependências. |
| `SynapxRouteGuardRunner` | Investigar depois | Útil isoladamente, mas routing está fora do bounded context atual do Kortex. |
| `SynapxRouteScope` e `SynapxProvider` | Rejeitar | Duplicam `KortexScope`/`KortexProvider` e adicionam acoplamento de navegação. |
| `SynapxCommandView` | Não duplicar | `KortexResourceBuilder` já renderiza `Loading`/`Data`/`Error`; retry/idle só entram com contrato novo explícito. |
| `SynapxScope`/`SynapxObserver` | Não duplicar | `KortexWatch`, `KortexSelector` e `KortexListener` já definem os limites corretos. |
| Dialogs e `SynapxApp` | Rejeitar | Acoplam Material e composição de aplicativo ao pacote base. |

## Ordem recomendada

1. Especificar e testar coleções reativas (`KortexList`/`KortexMap` ou API
   equivalente).
2. Avaliar `once`/`interval` somente se `KortexEffect` não expressar o requisito
   claramente.
3. Avaliar cancelamento por geração/`runIfActive` comparando com
   `KortexResource` e `KortexCommand`.
4. Manter routing, módulos e widgets de conveniência fora do núcleo até existir
   requisito de produto independente.

## Critérios de aceite

- Nenhuma dependência de `synapx`, `dnolib` ou outro pacote externo.
- Nenhum import Flutter ou `BuildContext` em `lib/src/reactive/`.
- Operações após `dispose()` têm comportamento explícito e testado.
- Resultados assíncronos superados não alteram estado observável.
- Nenhuma duplicação de contratos existentes sem diferença semântica clara.
- Cada extração inclui testes focados e atualização documental no mesmo commit.

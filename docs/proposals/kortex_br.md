# Proposta: Pacote `kortex_br`

## 1. Objetivo & Posicionamento

Centralizar **validadores, formatadores (máscaras) e widgets especializados para padrões brasileiros**, retirando esse eixo específico de `kortex_lib` (ex.: `PhoneBrValidator`) e evitando duplicação entre apps.

- **Incluso**: validação, normalização (somente dígitos), formatação/máscara e widgets de entrada integrados ao `kortex_forms`.
- **Não Incluso**: clientes HTTP acoplados a um provedor específico (ex.: ViaCEP hardcoded — no máximo uma porta/interface opcional) ou regras de negócio de domínio.

---

## 2. Arquitetura em Duas Camadas (Pureza Dart vs Flutter)

Seguindo o mesmo princípio de separação do ecossistema (`INV-05`):

### Camada 1 — Núcleo Puro (`package:kortex_br/kortex_br.dart`)
- **Zero dependência de Flutter** (`dart:core` apenas), utilizável em domínio, backend Dart e testes unitários rápidos:
  - **Documentos**: `CpfValidator` / `CpfFormatter`, `CnpjValidator` / `CnpjFormatter` (dígitos verificadores + rejeição de sequências repetidas como `111.111.111-11`).
  - **Contato & Endereço**: `PhoneBrValidator` / `PhoneBrFormatter` (migração do `kortex_lib`), `CepValidator` / `CepFormatter`.
  - **Financeiro & Veículos**: `BrlCurrencyFormatter` / parser (`R$ 1.234,56` ↔ centavos `int`), `PixKeyValidator` (CPF/CNPJ/e-mail/telefone/EVP), `MercosulPlateValidator`.
  - **Normalização**: helpers `digitsOnly(String)` e `unmask(String)`.

### Camada 2 — Widgets de Entrada (`package:kortex_br/widgets.dart`)
- **Dependência opcional de Flutter + `kortex_forms`**:
  - `KortexCpfField`, `KortexCnpjField`, `KortexPhoneBrField`, `KortexCepField`, `KortexBrlCurrencyField`.
  - Cada widget já aplica `TextInputFormatter` + `keyboardType` adequado + `maxLength` + integração direta com `KortexField<String>` (ou `KortexField<int>` para centavos).

---

## 3. Governança & Gate de Entrada

1. **Quando criar**: **após a `EPIC10`** (ou, no mínimo, após `UC-10.03` em `kortex_forms` e `UC-10.05` de fronteira de API), para não construir widgets sobre contratos ainda em hardening.
2. **Migração limpa**: `PhoneBrValidator` sai de `kortex_lib` para `kortex_br` (com `@Deprecated` em `kortex_lib` durante um ciclo menor, se já publicado).
3. **Qualidade mínima**:
   - Testes unitários cobrindo casos de borda (zeros à esquerda, dígitos verificadores, strings vazias/sujas).
   - Testes de widget validando máscara + digitação + erro no `KortexField`.
   - Zero dependências de terceiros no núcleo puro.

---

## 4. Decisão Arquitetural Pendente (parecer 2026-11-26)

**Problema**: "duas camadas, um pacote" é inexequível como escrito — dependência no pub não é opcional. Se `lib/widgets.dart` importar `flutter`/`kortex_forms`, o `pubspec` do pacote as declara e o "núcleo puro utilizável em backend Dart" deixa de existir.

**Recomendação**: dois pacotes no workspace:

- **`kortex_br`** (puro): `sdk: dart`, zero dependências. Só validadores, formatadores, normalização e parser BRL↔centavos (`int`, sem `double` no caminho feliz).
- **`kortex_br_widgets`** (Flutter): depende de `flutter` + `kortex_forms` + `kortex_br`. Só os `KortexXxxField` (`TextInputFormatter` + `keyboardType` + `maxLength` + binding a `KortexField`).

**Alternativa descartada**: um pacote só com dep Flutter e arquivos puros sem import (é o que o `brlib` já faz) — preserva o status quo, mas invalida a alegação de uso em backend Dart. Só aceitar se o requisito backend for abandonado explicitamente.

## 5. Inventário de Migração (esqueleto — completar no fatiamento)

| Origem em `kortex_lib/brlib` | Destino proposto | Veredito preliminar |
| --- | --- | --- |
| `validators/cpf_validator.dart`, `formatters/cpf_formatter.dart`, `cpf.dart` | `kortex_br` | Migra |
| `validators/cnpj_validator.dart`, `formatters/cnpj_formatter.dart` | `kortex_br` | Migra |
| `validators/phone_br_validator.dart`, `formatters/phone_br_formatter.dart` | `kortex_br` | Migra (caso canônico do split) |
| `validators/cep_validator.dart`, `formatters/cep_formatter.dart` | `kortex_br` | Migra |
| `validators/uf_validator.dart`, `endereco.dart`, `document.dart` | `kortex_br` | Migra (avaliar se `document.dart` é agregador a dissolver) |
| `money_brl.dart` (extensão sobre `Money` do `core/`) | `kortex_br` como funções puras `String ↔ int` centavos | **Redesenhar**: não arrastar `Money`/`core/` junto; `Money` permanece no `kortex_lib` |
| `input_formatters/currency_input_formatter.dart` vs `money_input_formatter.dart` | `kortex_br_widgets` (um só) | **Resolver duplicação**: um sobrevive, outro morre |
| Demais `input_formatters/*` (`date`, `integer`, `number`, `digit_mask`, `cpf/cnpj/cep/phone`) | `kortex_br_widgets` | Migra (avaliar se genéricos como `date`/`integer`/`number` pertencem a um pacote BR) |
| `src/validators/validator_utils.dart` (fora do barrel) | — | Auditar: expor, internalizar ou eliminar |

Regra de migração: cada item migra com `@Deprecated` em `kortex_lib` por um ciclo menor + entrada em `CHANGELOG.md` + guia; item que morre tem justificativa registrada.

## 6. Contratos a Especificar (DoR do épico de implementação)

- **`PixKeyValidator`**: gramáticas por tipo (CPF/CNPJ/e-mail/telefone/EVP-UUID); tabela de aceitação com bordas (zeros à esquerda, repetidos, vazio/sujo, `null`).
- **`MercosulPlateValidator`**: padrão antigo × Mercosul, tolerância a hífen/caixa; idem.
- **`CepValidator`**: só formato `NNNNN-NNN` ou também faixa numérica válida.
- **`digitsOnly`/`unmask`**: semântica para `null`/vazio consistente com o fix de `T?` da `UC-10.03`.
- **`keyboardType`/`maxLength` por campo**: documentar por widget (ex.: CEP 8 dígitos crus vs 9 com máscara).
- **Qualidade**: além dos exemplos fixos, teste de propriedade/fuzz nos DVs (gerar válido, corromper 1 dígito) + gate "nenhum import Flutter no núcleo" no CI.

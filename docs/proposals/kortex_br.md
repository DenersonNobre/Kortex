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

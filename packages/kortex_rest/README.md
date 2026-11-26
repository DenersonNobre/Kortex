# kortex_rest

Thin HTTP client helpers, retry, and middleware over `http.Client` for Kortex apps — without `sqflite`.

## Quando usar / Quando NÃO usar
- **Quando usar**: chamadas REST com retry, timeout e middleware sobre `http.Client` (testável com `MockClient`).
- **Quando NÃO usar**: quando precisar apenas de `IResult`/`Money`/utilitários puros (use `kortex_core`).

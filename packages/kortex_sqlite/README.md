# kortex_sqlite

SQLite provider and versioned migrations for Kortex apps — without `http`.

## Quando usar / Quando NÃO usar
- **Quando usar**: persistência relacional local com `sqflite` e migrations versionadas.
- **Quando NÃO usar**: quando precisar apenas de `IResult`/`Money`/utilitários puros (use `kortex_core`).

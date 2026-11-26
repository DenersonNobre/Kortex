# kortex_core

Core patterns (`IResult`, `IUseCase`), `Money`, `Logger`, `SecretCipher`, `Debouncer`, `AsyncCache`, `AsyncLock`, `StateMachine`, `Specification`, `PageResult`, `UserSession`, and validators — without `http` or `sqflite`.

## Quando usar / Quando NÃO usar
- **Quando usar**: domínio, casos de uso, `IResult`, `Money`, logging e utilitários compartilhados.
- **Quando NÃO usar**: não usar `SecretCipher` para segredos críticos em produção (AES-CFB64 sem AEAD/salt).

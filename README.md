# Kortex

Monorepo Flutter/Dart modular para gerenciamento de estado, formulários, persistência, rede e widgets reutilizáveis, sem dependências externas no núcleo reativo.

## Pacotes

| Pacote | Responsabilidade |
| --- | --- |
| `kortex_state` | Núcleo reativo puro (`KortexSignal`, `KortexComputed`, `KortexResource`), `KortexScope` e widgets reativos |
| `kortex_core` | Primitivas de domínio (`Result`, erros tipados, contratos base) |
| `kortex_forms` | `KortexField`, `KortexForm` e validação reativa |
| `kortex_br` | Validadores e máscaras brasileiras (CPF, CNPJ, CEP, telefone, BRL) |
| `kortex_widgets` | Widgets de UI reutilizáveis (`AsyncListView`, `AsyncPage`, `SearchableSelect`, `FilterPanel`, `FormErrorSummary`, `KortexDateField`, campos BR) |
| `kortex_persist` | Abstrações de persistência local |
| `kortex_sqlite` | Implementação SQLite para persistência |
| `kortex_rest` | Cliente e contratos REST |
| `kortex_lint` | Regras de lint customizadas do ecossistema Kortex |
| `kortex_lib` | Pacote agregador |

## Comandos

```powershell
flutter pub get
flutter analyze
flutter test
```

Consulte o `README.md` e o `example/lib/main.dart` dentro de cada pacote em `packages/` para exemplos de uso.

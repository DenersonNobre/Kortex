# kortex_cli

CLI em Dart puro para gerar a estrutura canônica de apps e módulos Kortex (`StatelessWidget`-first, `KortexScope`, `IKortexController`, `AppRoutes`/`AppPages` com `Navigator` nativo e testes).

## Instalação

```powershell
dart pub global activate kortex_cli
```

Ou execute diretamente a partir do monorepo:

```powershell
dart run packages/kortex_cli/bin/kortex.dart help
```

## Comandos

| Comando | Descrição |
| --- | --- |
| `kortex create <app_name>` | Cria a estrutura base do app em `<app_name>/` |
| `kortex module <module_name>` | Cria uma fatia vertical completa em `lib/modules/<module_name>/` |
| `kortex page <module_name> <page>` | Adiciona `<page>_page.dart` + `<page>_controller.dart` em `lib/modules/<module_name>/ui/` |
| `kortex help` | Exibe a ajuda dos comandos |

## Estrutura gerada

### `kortex create meu_app`

```text
meu_app/
├── pubspec.yaml                  # Dependências base (kortex, kortex_core, kortex_widgets)
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart              # MaterialApp com AppRoutes + AppPages
│   │   └── routes/
│   │       ├── app_routes.dart
│   │       └── app_pages.dart
│   ├── core/
│   └── modules/
└── test/
    └── widget_test.dart
```

### `kortex module work_orders`

```text
lib/modules/work_orders/
├── domain/
├── data/
├── features/
└── ui/
    ├── work_orders_controller.dart   # IKortexController + autoDispose
    ├── work_orders_page.dart         # StatelessWidget + KortexWatch
    └── work_orders_routes.dart       # MaterialPageRoute + KortexScope
test/modules/work_orders/
└── work_orders_controller_test.dart
```

### `kortex page work_orders detail`

Gera `detail_page.dart` (`StatelessWidget`) e `detail_controller.dart` (`IKortexController`) dentro de `lib/modules/work_orders/ui/`.

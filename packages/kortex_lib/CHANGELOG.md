# Changelog — kortex_lib

## [0.1.1] - 2026-11-23

### Added

- Static `validate(String? source, [String message])` helpers on `CpfValidator`, `CnpjValidator`, `CepValidator`, `PhoneBrValidator`, and `UfValidator` for direct compatibility with `kortex_forms` and `TextFormField`.

## [0.1.0] - 2026-11-23

### Added

- Initial release bundling `brlib`, `core`, `rest`, `sqlite`, and `widgets` with `package:kortex/kortex.dart` re-exported from `package:kortex_lib/kortex_lib.dart`.

## [Unreleased]

### Removed (breaking)

- `brlib/` (validadores/formatadores BR) e `widgets/` removidos integralmente; migrados para `kortex_br` (núcleo puro) e `kortex_widgets` (`src/br/` + `src/widgets/`) — ver EPIC11. Consumidores devem trocar o import para os novos pacotes.

### Deprecated
- `brlib/brlib.dart` export in `kortex_lib` — migrate to `package:kortex_br/kortex_br.dart` (pure Dart) and `package:kortex_widgets/kortex_widgets.dart` (BR input fields) (`UC-11.03`).

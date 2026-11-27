# Changelog — kortex_widgets

## [Unreleased]

### Added
- `AsyncListView` + `AsyncListController` (paged list: pull-to-refresh, scroll-to-load-more, tail retry, fixed-height skeleton without layout shift; `UC-12.01`).
- `AsyncPage` (single-resource scaffold over a caller-owned `KortexResource`: loading/error-with-retry/data, no empty flash, caller-owned dispose; `UC-12.02`).
- `SearchableSelectController` + `SearchableSelectSheet` + `showSearchableSelect` (single/multi pick with debounced async search, generation-based cancellation, confirm delivering the checked list; `UC-12.03`).

### Changed
- `PresenterScope`, `PresenterContextExtension` and `PresenterView` are now `@Deprecated` (use `KortexScope` + `IKortexController` from `package:kortex/kortex.dart` instead). No behavior change (`UC-12.00`).

## [0.1.0] - 2026-11-26

### Added
- Brazilian masked input fields (`KortexCpfField`, `KortexCnpjField`, `KortexCepField`, `KortexPhoneBrField`, `KortexBrlCurrencyField`) integrated with `kortex_forms` (`UC-11.02`).

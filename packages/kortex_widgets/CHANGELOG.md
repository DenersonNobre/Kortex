# Changelog — kortex_widgets

## [Unreleased]

### Added
- `AsyncListView` + `AsyncListController` (paged list: pull-to-refresh, scroll-to-load-more, tail retry, fixed-height skeleton without layout shift; `UC-12.01`).

### Changed
- `PresenterScope`, `PresenterContextExtension` and `PresenterView` are now `@Deprecated` (use `KortexScope` + `IKortexController` from `package:kortex/kortex.dart` instead). No behavior change (`UC-12.00`).

## [0.1.0] - 2026-11-26

### Added
- Brazilian masked input fields (`KortexCpfField`, `KortexCnpjField`, `KortexCepField`, `KortexPhoneBrField`, `KortexBrlCurrencyField`) integrated with `kortex_forms` (`UC-11.02`).

# Changelog — kortex_widgets

## [Unreleased]

### Added
- `AsyncListView` + `AsyncListController` (paged list: pull-to-refresh, scroll-to-load-more, tail retry, fixed-height skeleton without layout shift; `UC-12.01`).
- `AsyncPage` (single-resource scaffold over a caller-owned `KortexResource`: loading/error-with-retry/data, no empty flash, caller-owned dispose; `UC-12.02`).
- `SearchableSelectController` + `SearchableSelectSheet` + `showSearchableSelect` (single/multi pick with debounced async search, generation-based cancellation, confirm delivering the checked list; `UC-12.03`).
- `FilterOption` + `FilterPanelController` + `FilterPanel` (single/multi reactive chips with stable width across selection flips via a always-reserved check slot, `onSelectionChanged` for filter signals, caller-owned dispose; `UC-12.04`).
- `FormErrorTarget` + `FormErrorSummary` (reactive error list over a caller-owned `KortexForm`: one tappable row per failing mapped field, tap scrolls the caller-owned `GlobalKey` anchor into view, valid form renders nothing; `UC-12.05`).
- Integration guide `OtpPinField` + `KortexField<String>` via `pinput` (spike verdict `USAR_PINPUT` in `docs/notes/pinput-spike.md`): README-only, no widget shipped, `smart_auth` stays opt-in of the consuming app (`UC-12.16`).

### Changed
- `PresenterScope`, `PresenterContextExtension` and `PresenterView` are now `@Deprecated` (use `KortexScope` + `IKortexController` from `package:kortex/kortex.dart` instead). No behavior change (`UC-12.00`).

## [0.1.0] - 2026-11-26

### Added
- `KortexCpfField`, `KortexCnpjField`, `KortexCepField`, `KortexPhoneBrField`, `KortexBrlCurrencyField` (`UC-11.02`).
- `KortexDateField` and `KortexDateRangeField` with pure Dart `dd/MM/yyyy` parsing (`UC-12.06`).

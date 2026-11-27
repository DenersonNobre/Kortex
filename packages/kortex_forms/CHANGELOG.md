# Changelog — kortex_forms

## [Unreleased]

### Added
- `kortex_credentials.dart` (`Email`, `Senha` VOs) moved from `kortex_core`.

### Fixed
- `KortexField.reset()` now distinguishes omitted argument from explicit `null` on nullable fields (`UC-10.03`).

## [0.1.1] - 2026-11-23

### Added

- `KortexValidatorBuilder<T>` / `kortexValidator<T>()` with fluent string rules (`required`, `minLength`, `maxLength`, `email`, `pattern`, `must`, `use`, `build`).

## [0.1.0] - 2026-11-23

### Added

- `KortexField<T>` / `kortexField<T>()` with synchronous validators, `touched`/`dirty` tracking, `validate()`, `reset()`, and `dispose()`.
- `KortexForm` / `kortexForm()` for coordinated multi-field validation, reset, and disposal.

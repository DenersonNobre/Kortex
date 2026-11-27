# Changelog — kortex_core

## [Unreleased]

### Added
- `LogCorrelation`, `FileLogSink` (with rotation), `BufferedLogSink`, and `AnsiTextLogFormatter`.

### Changed
- Removed `kortex_forms` dependency by moving `credentials` to `kortex_forms`.

## [0.1.0] - 2026-11-26

### Added
- Extracted `core/` from `kortex_lib` without `http` or `sqflite` (`UC-13.01`).

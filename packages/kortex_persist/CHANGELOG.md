# Changelog — kortex_persist

## [Unreleased]

### Added
- `flush()`, `onError` (`KortexPersistErrorHandler`), and `lastError` on `KortexPersistedSignal` (`UC-10.02`).

### Fixed
- Serialized storage operations and prevented stale `hydrate()` from overwriting local mutations.

## [0.1.0] - 2026-11-22

### Added

- `IKortexStorage` pluggable key-value storage contract and `KortexMemoryStorage`.
- `KortexPersistedSignal<T>` and `kortexPersistedSignal<T>()` with automatic hydration, persistence and `clear()`.

# kortex_widgets

Reusable Flutter UI widgets (`src/widgets/`) and Brazilian input fields (`src/br/`) for Kortex.

## Included
- **BR Input Fields (`src/br/`)**: `KortexCpfField`, `KortexCnpjField`, `KortexCepField`, `KortexPhoneBrField`, `KortexBrlCurrencyField`, `KortexMaskedBrField` (integrated with `kortex_br` and `kortex_forms`).
- **UI Widgets (`src/widgets/`)**: `ActionBar`, `Alert`, `AsyncImage`, `AsyncListView`, `BusyOverlay`, `CardTile`, `Details`, `Labels`, `Modals`, `PillField`, `PresenterView`, `Reactive`, `SearchPanel`, `Snapshots`, `StatTile`, `StateViews`, `StatusChip`, `Titles`.

## `AsyncListView` (UC-12.01)

Paged list with pull-to-refresh, scroll-to-load-more and a fixed-height
skeleton, driven by `AsyncListController` (first page in a `KortexResource`,
tail with race protection and duplicate suppression).

- **Use when** a screen shows a paged source (cursor/offset) with
  loading/empty/error/retry handled in one piece.
- **Do NOT use when** the list is static (a plain `ListView` is enough), when
  the source pushes realtime updates (use a `StreamSnapshot`/`KortexWatch`
  over the stream instead), or when rows need business rules (those live in
  the domain/commands layer, never in the row builder).
- **Ownership**: the caller creates `AsyncListController` (injecting
  `loadPage`) and disposes it; the widget never disposes it (unmount keeps
  it alive, proven in `test/widgets/async_list_view_test.dart`).

## When NOT to use `PresenterScope`

`PresenterScope`, `PresenterView` and `BuildContext.presenter` are deprecated
(`UC-12.00`): do not use them in new code. Use `KortexScope` with an
`IKortexController` from `package:kortex/kortex.dart` instead
(`KortexProvider<T>.value` for externally owned instances,
`context.readKortex<T>()` to resolve).

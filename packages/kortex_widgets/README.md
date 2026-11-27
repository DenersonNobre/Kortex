# kortex_widgets

Reusable Flutter UI widgets (`src/widgets/`) and Brazilian input fields (`src/br/`) for Kortex.

## Included
- **BR Input Fields (`src/br/`)**: `KortexCpfField`, `KortexCnpjField`, `KortexCepField`, `KortexPhoneBrField`, `KortexBrlCurrencyField`, `KortexMaskedBrField` (integrated with `kortex_br` and `kortex_forms`).
- **UI Widgets (`src/widgets/`)**: `ActionBar`, `Alert`, `AsyncImage`, `AsyncListView`, `AsyncPage`, `BusyOverlay`, `CardTile`, `Details`, `FilterPanel`, `Labels`, `Modals`, `PillField`, `PresenterView`, `Reactive`, `SearchPanel`, `SearchableSelect`, `Snapshots`, `StatTile`, `StateViews`, `StatusChip`, `Titles`.

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

## `AsyncPage` (UC-12.02)

Single-resource scaffold driven by a caller-owned `KortexResource<T>`:
loading shows `Loading` (or `loadingBuilder`), error shows `ErrorRetryView`
with a retry that calls `resource.refresh()` (or `errorBuilder`), and data
goes straight to `contentBuilder` — no empty flash on the loading→data
path.

- **Use when** a screen shows one async value (detail, profile, settings)
  with loading/error/retry handled in one piece.
- **Do NOT use when** the source is paged (use `AsyncListView`), pushes
  realtime updates (use a stream snapshot), or needs an empty branch (a
  `KortexAsyncData` holding an empty collection is still data — branch on
  the value inside `contentBuilder` if needed).
- **Ownership**: the caller creates `KortexResource` and disposes it; the
  widget never disposes it (unmount keeps it alive, in-flight dispose drops
  the late result silently, proven in
  `test/widgets/async_page_test.dart`).

## `SearchableSelect` (UC-12.03)

Single/multi selection with async search in a bottom-sheet body, driven by
a caller-owned `SearchableSelectController` (debounced `optionsLoader`,
generation-based cancellation: only the latest result renders, stale loads
drop silently).

- **Use when** a form needs single/multi pick from an async source
  (search-as-you-type) without a heavy third-party picker; confirm delivers
  the checked list to `onConfirm` (ready to feed a `KortexField`, no forms
  coupling in this package).
- **Do NOT use when** options are static and few (a `DropdownButton`/
  `ChoiceChip` row is enough), when the source pushes realtime updates, or
  when picking involves business rules (those live in the domain/commands
  layer, never in the sheet).
- **Ownership**: the caller creates `SearchableSelectController` (injecting
  `optionsLoader`) and disposes it; the sheet never disposes it (unmount
  keeps it alive, in-flight dispose drops the late result silently, proven
  in `test/widgets/searchable_select_test.dart`).

## `FilterPanel` (UC-12.04)

Single/multi chip row driven by a caller-owned `FilterPanelController`
(single replaces, multi accumulates) with `onSelectionChanged` delivering
the checked set (ready to feed filter signals). Chips keep a stable width
across selection flips: the check slot is always reserved
(`showCheckmark: false` + fixed-size avatar), so selecting never reflows
the row (proven by the `getRect`-identical geometric test with explicit
tolerance in `test/widgets/filter_panel_test.dart`).

- **Use when** a screen shows static filter chips synced with signals
  (single or multi) and layout stability matters.
- **Do NOT use when** options load asynchronously with search (use
  `SearchableSelect`), when picking involves business rules (those live in
  the domain/commands layer, never in the panel), or when chips need
  per-option custom rendering beyond label + check.
- **Ownership**: the caller creates `FilterPanelController` and disposes
  it; the panel never disposes it (unmount keeps it alive, use after
  dispose throws `StateError`, proven in
  `test/widgets/filter_panel_test.dart`).

## When NOT to use `PresenterScope`

`PresenterScope`, `PresenterView` and `BuildContext.presenter` are deprecated
(`UC-12.00`): do not use them in new code. Use `KortexScope` with an
`IKortexController` from `package:kortex/kortex.dart` instead
(`KortexProvider<T>.value` for externally owned instances,
`context.readKortex<T>()` to resolve).

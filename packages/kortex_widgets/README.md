# kortex_widgets

Reusable Flutter UI widgets (`src/widgets/`) and Brazilian input fields (`src/br/`) for Kortex.

## Included
- **BR Input Fields (`src/br/`)**: `KortexCpfField`, `KortexCnpjField`, `KortexCepField`, `KortexPhoneBrField`, `KortexBrlCurrencyField`, `KortexMaskedBrField` (integrated with `kortex_br` and `kortex_forms`).
- **UI Widgets (`src/widgets/`)**: `ActionBar`, `Alert`, `AsyncImage`, `BusyOverlay`, `CardTile`, `Details`, `Labels`, `Modals`, `PillField`, `PresenterView`, `Reactive`, `SearchPanel`, `Snapshots`, `StatTile`, `StateViews`, `StatusChip`, `Titles`.

## When NOT to use `PresenterScope`

`PresenterScope`, `PresenterView` and `BuildContext.presenter` are deprecated
(`UC-12.00`): do not use them in new code. Use `KortexScope` with an
`IKortexController` from `package:kortex/kortex.dart` instead
(`KortexProvider<T>.value` for externally owned instances,
`context.readKortex<T>()` to resolve).

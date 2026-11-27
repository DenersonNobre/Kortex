import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// One selectable entry of a [FilterPanel] (pure value, without rule).
class FilterOption<T> {
  /// Creates the entry mapping [value] to its visible [label].
  const FilterOption({required this.value, required this.label});

  /// Identity held in the selection set (compared with `==`).
  final T value;

  /// Visible chip label (pure mapping, without business rule).
  final String label;
}

/// Receives the current selection after every toggle (single mode holds
/// zero or one value).
typedef FilterSelectionCallback<T> = void Function(Set<T> selection);

/// Single/multi selection state for a [FilterPanel] (`UC-12.04`).
///
/// SRP: hold the checked set in a [KortexSignal] and flip it through
/// [toggle]. It does NOT fetch, filter, own text controllers nor dispose
/// anything it did not create.
class FilterPanelController<T> implements IKortexDisposable {
  /// Creates the state; [multi] selects between accumulate or replace.
  FilterPanelController({
    List<T> initialSelection = const [],
    this.multi = true,
  }) : _selected = KortexSignal<Set<T>>(Set<T>.unmodifiable(initialSelection));

  static const _disposedMessage = 'FilterPanelController used after dispose()';

  /// Whether [toggle] accumulates (multi) or replaces (single).
  final bool multi;

  final KortexSignal<Set<T>> _selected;
  var _isDisposed = false;

  /// Whether the controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Checked values, in toggle order.
  IKortexReadonlySignal<Set<T>> get selected => _selected.readonly;

  /// Checks or unchecks [value] (replaces the set in single mode).
  void toggle(T value) {
    _requireAlive();
    if (multi) {
      _toggleMulti(value);
      return;
    }
    _selected.value = Set<T>.unmodifiable(<T>{value});
  }

  /// Unchecks every value.
  void clearSelection() {
    _requireAlive();
    _selected.value = Set<T>.unmodifiable(<T>{});
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _selected.dispose();
  }

  void _toggleMulti(T value) {
    final current = Set<T>.of(_selected.peek());
    if (current.contains(value)) {
      current.remove(value);
      _selected.value = Set<T>.unmodifiable(current);
      return;
    }
    current.add(value);
    _selected.value = Set<T>.unmodifiable(current);
  }

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Reactive chip row with stable width across selection flips (`UC-12.04`).
///
/// SRP: render [options] from [controller] as chips whose width never moves
/// (the check slot is always reserved, so selecting never reflows the row)
/// and report the set through [onSelectionChanged]. It does NOT own nor
/// dispose [controller] (the caller creates and disposes it; unmount keeps
/// it alive).
class FilterPanel<T> extends StatelessWidget {
  /// Creates the panel over an externally owned [controller].
  const FilterPanel({
    super.key,
    required this.options,
    required this.controller,
    this.onSelectionChanged,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.checkIcon = Icons.check,
  });

  /// Selectable entries, in display order.
  final List<FilterOption<T>> options;

  /// Selection state (owned and disposed by the caller).
  final FilterPanelController<T> controller;

  /// Receives the checked set after every toggle (filter-signal ready).
  final FilterSelectionCallback<T>? onSelectionChanged;

  /// Horizontal gap between chips.
  final double spacing;

  /// Vertical gap between chip rows.
  final double runSpacing;

  /// Glyph of the reserved check slot (fixed size, always laid out).
  final IconData checkIcon;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        final selected = controller.selected.value;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final option in options)
              _StableChip<T>(
                option: option,
                isSelected: selected.contains(option.value),
                checkIcon: checkIcon,
                onTap: () {
                  controller.toggle(option.value);
                  onSelectionChanged?.call(controller.selected.peek());
                },
              ),
          ],
        );
      },
    );
  }
}

class _StableChip<T> extends StatelessWidget {
  const _StableChip({
    required this.option,
    required this.isSelected,
    required this.checkIcon,
    required this.onTap,
  });

  final FilterOption<T> option;
  final bool isSelected;
  final IconData checkIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: ValueKey<String>('filter_${option.label}'),
      label: Text(option.label),
      selected: isSelected,
      showCheckmark: false,
      avatar: SizedBox.square(
        dimension: 18,
        child: isSelected ? Icon(checkIcon, size: 18) : null,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

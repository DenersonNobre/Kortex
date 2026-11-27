import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'modals.dart';
import 'state_views.dart';

/// Loads the options matching [query] (empty query loads the default set).
typedef SearchableOptionsLoader<T> = Future<List<T>> Function(String query);

/// Visible label of one [option] (pure mapping, without business rule).
typedef SearchableOptionLabel<T> = String Function(T option);

/// Receives the confirmed selection (single mode holds zero or one item).
typedef SearchableConfirmCallback<T> = void Function(List<T> selection);

/// Search plus selection state with cancellation for `SearchableSelectSheet`.
///
/// SRP: run [optionsLoader] under [debounce], drop stale conclusions by
/// generation and hold the checked set. It does NOT render, open sheets,
/// own text controllers nor dispose anything it did not create.
class SearchableSelectController<T> implements IKortexDisposable {
  /// Creates the state over [optionsLoader].
  ///
  /// With [multi] every [toggle] adds or removes one option; in single
  /// mode [toggle] replaces the selection. With [immediate] the default
  /// set loads at once.
  SearchableSelectController({
    required SearchableOptionsLoader<T> optionsLoader,
    List<T> initialSelection = const [],
    this.multi = true,
    this.debounce = const Duration(milliseconds: 250),
    bool immediate = true,
  }) : _optionsLoader = optionsLoader,
       _query = KortexSignal<String>(''),
       _options = KortexSignal<List<T>>(List<T>.unmodifiable(<T>[])),
       _isLoading = KortexSignal<bool>(false),
       _error = KortexSignal<Object?>(null),
       _selected = KortexSignal<List<T>>(
         List<T>.unmodifiable(initialSelection),
       ) {
    if (immediate) {
      unawaited(search(''));
    }
  }

  static const _disposedMessage =
      'SearchableSelectController used after dispose()';

  final SearchableOptionsLoader<T> _optionsLoader;

  /// Whether [toggle] accumulates (multi) or replaces (single).
  final bool multi;

  /// Delay between keystrokes and the load ([Duration.zero] skips the timer).
  final Duration debounce;

  final KortexSignal<String> _query;
  final KortexSignal<List<T>> _options;
  final KortexSignal<bool> _isLoading;
  final KortexSignal<Object?> _error;
  final KortexSignal<List<T>> _selected;
  Timer? _debounceTimer;
  var _generation = 0;
  var _isDisposed = false;

  /// Whether the controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Last query sent to [optionsLoader].
  IKortexReadonlySignal<String> get query => _query.readonly;

  /// Last concluded option list (stale loads never land here).
  IKortexReadonlySignal<List<T>> get options => _options.readonly;

  /// Whether a search is in flight.
  IKortexReadonlySignal<bool> get isLoading => _isLoading.readonly;

  /// Last search failure, or `null`.
  IKortexReadonlySignal<Object?> get error => _error.readonly;

  /// Checked options, in toggle order.
  IKortexReadonlySignal<List<T>> get selected => _selected.readonly;

  /// Searches [query] under [debounce]; an older in-flight search loses.
  Future<void> search(String query) {
    _requireAlive();
    _query.value = query;
    _debounceTimer?.cancel();
    final generation = ++_generation;
    final pending = Completer<void>();
    if (debounce == Duration.zero) {
      unawaited(_runSearch(query, generation, pending));
      return pending.future;
    }
    _debounceTimer = Timer(debounce, () {
      unawaited(_runSearch(query, generation, pending));
    });
    return pending.future;
  }

  /// Checks or unchecks [option] (replaces the set in single mode).
  void toggle(T option) {
    _requireAlive();
    if (multi) {
      _toggleMulti(option);
      return;
    }
    _selected.value = List<T>.unmodifiable(<T>[option]);
  }

  /// Unchecks every option.
  void clearSelection() {
    _requireAlive();
    _selected.value = List<T>.unmodifiable(<T>[]);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _generation++;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _query.dispose();
    _options.dispose();
    _isLoading.dispose();
    _error.dispose();
    _selected.dispose();
  }

  void _toggleMulti(T option) {
    final current = List<T>.of(_selected.peek());
    if (current.contains(option)) {
      current.remove(option);
      _selected.value = List<T>.unmodifiable(current);
      return;
    }
    current.add(option);
    _selected.value = List<T>.unmodifiable(current);
  }

  Future<void> _runSearch(
    String query,
    int generation,
    Completer<void> pending,
  ) async {
    try {
      if (!_isCurrent(generation)) return;
      _setLoading(true);
      _setError(null);
      try {
        final loaded = await _optionsLoader(query);
        if (!_isCurrent(generation)) return;
        _options.value = List<T>.unmodifiable(loaded);
      } catch (error) {
        if (!_isCurrent(generation)) return;
        _setError(error);
      } finally {
        if (_isCurrent(generation)) _setLoading(false);
      }
    } finally {
      if (!pending.isCompleted) pending.complete();
    }
  }

  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading.value = value;
  }

  void _setError(Object? error) {
    if (_isDisposed) return;
    _error.value = error;
  }

  bool _isCurrent(int generation) =>
      !_isDisposed && generation == _generation;

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Bottom-sheet body for single or multi selection with async search.
///
/// SRP: render [controller] (search field, loading skeleton, empty, error
/// with retry, option list, confirm) and report the checked set through
/// [onConfirm]. It does NOT load, own nor dispose [controller] (the caller
/// creates and disposes it; unmount keeps it alive). The search text
/// controller belongs to this sheet state and dies with it.
class SearchableSelectSheet<T> extends StatefulWidget {
  /// Creates the sheet over an externally owned [controller].
  const SearchableSelectSheet({
    super.key,
    required this.controller,
    required this.optionLabel,
    this.onConfirm,
    this.title = 'Select',
    this.searchHint = 'Search',
    this.confirmLabel = 'Confirm',
    this.emptyTitle = 'No options',
    this.retryLabel = 'Retry',
  });

  /// Search plus selection state (owned and disposed by the caller).
  final SearchableSelectController<T> controller;

  /// Visible label of one option.
  final SearchableOptionLabel<T> optionLabel;

  /// Receives the checked set when confirm is tapped (KortexField-ready).
  final SearchableConfirmCallback<T>? onConfirm;

  /// Sheet title.
  final String title;

  /// Hint of the search field.
  final String searchHint;

  /// Label of the confirm affordance.
  final String confirmLabel;

  /// Title of the empty branch.
  final String emptyTitle;

  /// Tooltip of every retry affordance.
  final String retryLabel;

  @override
  State<SearchableSelectSheet<T>> createState() =>
      _SearchableSelectSheetState<T>();
}

class _SearchableSelectSheetState<T>
    extends State<SearchableSelectSheet<T>> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModalHeader(title: widget.title),
            const Divider(),
            TextField(
              key: const ValueKey<String>('search'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: widget.controller.search,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: KortexWatch(
                builder: (context, _) {
                  final loading = widget.controller.isLoading.value;
                  final failure = widget.controller.error.value;
                  final options = widget.controller.options.value;
                  final selected = widget.controller.selected.value;
                  if (loading && options.isEmpty) {
                    return const Loading();
                  }
                  if (failure != null && options.isEmpty) {
                    return ErrorRetryView(
                      message: failure.toString(),
                      onRetry: () {
                        unawaited(
                          widget.controller.search(
                            widget.controller.query.peek(),
                          ),
                        );
                      },
                      retryTooltip: widget.retryLabel,
                    );
                  }
                  if (options.isEmpty) {
                    return EmptyState(title: widget.emptyTitle);
                  }
                  return _OptionsList<T>(
                    controller: widget.controller,
                    options: options,
                    selected: selected,
                    optionLabel: widget.optionLabel,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            KortexWatch(
              builder: (context, _) {
                final selected = widget.controller.selected.value;
                return FilledButton(
                  key: const ValueKey<String>('confirm'),
                  onPressed: () {
                    widget.onConfirm?.call(
                      List<T>.unmodifiable(selected),
                    );
                  },
                  child: Text(widget.confirmLabel),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsList<T> extends StatelessWidget {
  const _OptionsList({
    required this.controller,
    required this.options,
    required this.selected,
    required this.optionLabel,
  });

  final SearchableSelectController<T> controller;
  final List<T> options;
  final List<T> selected;
  final SearchableOptionLabel<T> optionLabel;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey<String>('options'),
      shrinkWrap: true,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final checked = selected.contains(option);
        final label = optionLabel(option);
        if (controller.multi) {
          return CheckboxListTile(
            key: ValueKey<String>('option_$label'),
            title: Text(label),
            value: checked,
            onChanged: (_) => controller.toggle(option),
          );
        }
        return ListTile(
          key: ValueKey<String>('option_$label'),
          title: Text(label),
          trailing: checked ? const Icon(Icons.check) : null,
          selected: checked,
          onTap: () => controller.toggle(option),
        );
      },
    );
  }
}

/// Opens a [SearchableSelectSheet] as a modal bottom sheet.
///
/// SRP: host the sheet with the package [ModalHeader] chrome and pop the
/// confirmed set as the sheet result. It does NOT own [controller].
Future<List<T>?> showSearchableSelect<T>({
  required BuildContext context,
  required SearchableSelectController<T> controller,
  required SearchableOptionLabel<T> optionLabel,
  SearchableConfirmCallback<T>? onConfirm,
  String title = 'Select',
  String searchHint = 'Search',
  String confirmLabel = 'Confirm',
  String emptyTitle = 'No options',
  String retryLabel = 'Retry',
}) {
  return showModalBottomSheet<List<T>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SearchableSelectSheet<T>(
      controller: controller,
      optionLabel: optionLabel,
      onConfirm: (selection) {
        onConfirm?.call(selection);
        Navigator.of(sheetContext).pop(selection);
      },
      title: title,
      searchHint: searchHint,
      confirmLabel: confirmLabel,
      emptyTitle: emptyTitle,
      retryLabel: retryLabel,
    ),
  );
}

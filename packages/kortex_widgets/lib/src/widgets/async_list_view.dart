import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'state_views.dart';

/// Loads one page of items (0-based page index owned by the source).
typedef AsyncListPageLoader<T> = Future<List<T>> Function(int page);

/// Builds the row for [item] at [index] (kept at fixed [AsyncListView.itemExtent]).
typedef AsyncListItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

/// Pagination state with race protection for a paged list (`UC-12.01`).
///
/// SRP: accumulate pages from [loadPage], drop stale conclusions and keep the
/// first page in a [KortexResource]. It does NOT fetch beyond calling
/// [loadPage], retry on its own nor own scroll position.
class AsyncListController<T> implements IKortexDisposable {
  /// Creates the controller; with [immediate] the first page loads at once.
  AsyncListController({
    required AsyncListPageLoader<T> loadPage,
    bool immediate = true,
  }) : _loadPage = loadPage,
       head = KortexResource<List<T>>(() => loadPage(0), immediate: false),
       _items = KortexSignal<List<T>>(<T>[]),
       _isLoadingMore = KortexSignal<bool>(false),
       _tailError = KortexSignal<Object?>(null),
       _hasMore = KortexSignal<bool>(true) {
    if (immediate) {
      unawaited(refresh());
    }
  }

  static const _disposedMessage = 'AsyncListController used after dispose()';

  final AsyncListPageLoader<T> _loadPage;

  /// First page as a resource (loading/empty/error branches of the view).
  final KortexResource<List<T>> head;

  final KortexSignal<List<T>> _items;
  final KortexSignal<bool> _isLoadingMore;
  final KortexSignal<Object?> _tailError;
  final KortexSignal<bool> _hasMore;
  var _generation = 0;
  var _nextPage = 1;
  var _isDisposed = false;

  /// Whether the controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Accumulated items, without duplicates.
  IKortexReadonlySignal<List<T>> get items => _items.readonly;

  /// Whether a tail page is in flight.
  IKortexReadonlySignal<bool> get isLoadingMore => _isLoadingMore.readonly;

  /// Last tail failure, or `null`.
  IKortexReadonlySignal<Object?> get tailError => _tailError.readonly;

  /// Whether the source may still hold another page.
  IKortexReadonlySignal<bool> get hasMore => _hasMore.readonly;

  /// Reloads the first page; a `loadMore` in flight loses to this refresh.
  Future<void> refresh() async {
    _requireAlive();
    final generation = ++_generation;
    _setTailError(null);
    await head.refresh();
    if (!_isCurrent(generation)) return;
    _isLoadingMore.value = false;
    final state = head.state.peek();
    switch (state) {
      case KortexAsyncData<List<T>>(value: final value):
        _items.value = List<T>.unmodifiable(_appendDistinct(<T>[], value));
        _nextPage = 1;
        _hasMore.value = value.isNotEmpty;
      case KortexAsyncLoading<List<T>>():
      case KortexAsyncError<List<T>>():
        break;
    }
  }

  /// Appends the next page, ignoring re-entrant calls and stale results.
  Future<void> loadMore() async {
    _requireAlive();
    if (_isLoadingMore.peek()) return;
    if (!_hasMore.peek()) return;
    if (head.state.peek() is! KortexAsyncData<List<T>>) return;
    final generation = _generation;
    final page = _nextPage;
    _isLoadingMore.value = true;
    _setTailError(null);
    try {
      final loaded = await _loadPage(page);
      if (!_isCurrent(generation)) return;
      if (loaded.isEmpty) {
        _hasMore.value = false;
        return;
      }
      _items.value = List<T>.unmodifiable(
        _appendDistinct(_items.peek(), loaded),
      );
      _nextPage = page + 1;
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _setTailError(error);
    } finally {
      if (_isCurrent(generation)) _isLoadingMore.value = false;
    }
  }

  /// Clears the tail failure and loads the pending page again.
  Future<void> retryTail() {
    _requireAlive();
    _setTailError(null);
    return loadMore();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _generation++;
    head.dispose();
    _items.dispose();
    _isLoadingMore.dispose();
    _tailError.dispose();
    _hasMore.dispose();
  }

  List<T> _appendDistinct(List<T> base, List<T> incoming) {
    final merged = List<T>.of(base);
    for (final item in incoming) {
      if (merged.contains(item)) continue;
      merged.add(item);
    }
    return merged;
  }

  void _setTailError(Object? error) {
    if (_isDisposed) return;
    _tailError.value = error;
  }

  bool _isCurrent(int generation) => !_isDisposed && generation == _generation;

  void _requireAlive() {
    if (_isDisposed) throw StateError(_disposedMessage);
  }
}

/// Paged list with pull-to-refresh, scroll-to-load-more and stable skeleton.
///
/// SRP: render [controller] (loading skeleton, empty, error with retry, data
/// with tail) at a fixed [itemExtent]. It does NOT load pages, deduplicate
/// nor own the [controller] (the caller creates and disposes it).
class AsyncListView<T> extends StatelessWidget {
  /// Creates the view over an externally owned [controller].
  const AsyncListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.emptyTitle = 'No items',
    this.emptyMessage,
    this.headErrorMessage,
    this.tailErrorMessage,
    this.skeletonCount = 5,
    this.itemExtent = 72.0,
    this.retryLabel = 'Retry',
  });

  /// Pagination state (owned and disposed by the caller).
  final AsyncListController<T> controller;

  /// Row builder for one item.
  final AsyncListItemBuilder<T> itemBuilder;

  /// Copy of the empty branch.
  final String emptyTitle;

  /// Optional detail of the empty branch.
  final String? emptyMessage;

  /// Overrides the head error message (defaults to the failure text).
  final String? headErrorMessage;

  /// Overrides the tail error message (defaults to the failure text).
  final String? tailErrorMessage;

  /// Number of fixed-height placeholder rows while the first page loads.
  final int skeletonCount;

  /// Fixed row height, shared by skeleton and data rows (no layout shift).
  final double itemExtent;

  /// Label of every retry affordance.
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        final headState = controller.head.state.value;
        final items = controller.items.value;
        final loadingMore = controller.isLoadingMore.value;
        final tailFailure = controller.tailError.value;
        switch (headState) {
          case KortexAsyncLoading<List<T>>():
            return _SkeletonBody(
              skeletonKey: const ValueKey<String>('async_list_skeleton'),
              count: skeletonCount,
              itemExtent: itemExtent,
            );
          case KortexAsyncError<List<T>>(error: final failure):
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ErrorRetryView(
                  message: headErrorMessage ?? failure.toString(),
                  onRetry: controller.refresh,
                  retryTooltip: retryLabel,
                ),
              );
            }
            return _DataBody<T>(
              controller: controller,
              items: items,
              itemExtent: itemExtent,
              loadingMore: false,
              tailFailure: failure,
              tailMessage: tailErrorMessage,
              retryLabel: retryLabel,
              onTailRetry: controller.refresh,
              itemBuilder: itemBuilder,
            );
          case KortexAsyncData<List<T>>():
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: EmptyState(title: emptyTitle, message: emptyMessage),
              );
            }
            return _DataBody<T>(
              controller: controller,
              items: items,
              itemExtent: itemExtent,
              loadingMore: loadingMore,
              tailFailure: tailFailure,
              tailMessage: tailErrorMessage,
              retryLabel: retryLabel,
              onTailRetry: controller.retryTail,
              itemBuilder: itemBuilder,
            );
        }
      },
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({
    required this.skeletonKey,
    required this.count,
    required this.itemExtent,
  });

  final Key skeletonKey;
  final int count;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      key: skeletonKey,
      itemExtent: itemExtent,
      itemCount: count,
      itemBuilder: (context, index) => Padding(
        key: ValueKey<String>('async_list_skeleton_$index'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _DataBody<T> extends StatelessWidget {
  const _DataBody({
    required this.controller,
    required this.items,
    required this.itemExtent,
    required this.loadingMore,
    required this.tailFailure,
    required this.tailMessage,
    required this.retryLabel,
    required this.onTailRetry,
    required this.itemBuilder,
  });

  final AsyncListController<T> controller;
  final List<T> items;
  final double itemExtent;
  final bool loadingMore;
  final Object? tailFailure;
  final String? tailMessage;
  final String retryLabel;
  final Future<void> Function() onTailRetry;
  final AsyncListItemBuilder<T> itemBuilder;

  bool get _showsTail => loadingMore || tailFailure != null;

  @override
  Widget build(BuildContext context) {
    final itemCount = items.length + (_showsTail ? 1 : 0);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter <= 1.0) {
            unawaited(controller.loadMore());
          }
          return false;
        },
        child: ListView.builder(
          key: const ValueKey<String>('async_list_data'),
          itemExtent: itemExtent,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return _TailTile(
                loadingMore: loadingMore,
                message: tailFailure == null
                    ? null
                    : (tailMessage ?? tailFailure.toString()),
                retryLabel: retryLabel,
                onRetry: onTailRetry,
              );
            }
            return itemBuilder(context, items[index], index);
          },
        ),
      ),
    );
  }
}

class _TailTile extends StatelessWidget {
  const _TailTile({
    required this.loadingMore,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final bool loadingMore;
  final String? message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            message ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}

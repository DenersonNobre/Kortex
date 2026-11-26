import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_core/core/core.dart';

void main() {
  group('LoadingState', () {
    test('values check and state predicates', () {
      expect(LoadingState.initial.isInitial, isTrue);
      expect(LoadingState.initial.isLoading, isFalse);
      expect(LoadingState.initial.isLoaded, isFalse);
      expect(LoadingState.initial.isLoadingMore, isFalse);
      expect(LoadingState.initial.isError, isFalse);
      expect(LoadingState.initial.isBusy, isFalse);
      expect(LoadingState.initial.canLoadMore, isFalse);

      expect(LoadingState.loading.isLoading, isTrue);
      expect(LoadingState.loading.isBusy, isTrue);
      expect(LoadingState.loading.canLoadMore, isFalse);

      expect(LoadingState.loaded.isLoaded, isTrue);
      expect(LoadingState.loaded.isBusy, isFalse);
      expect(LoadingState.loaded.canLoadMore, isTrue);

      expect(LoadingState.loadingMore.isLoadingMore, isTrue);
      expect(LoadingState.loadingMore.isBusy, isTrue);
      expect(LoadingState.loadingMore.canLoadMore, isFalse);

      expect(LoadingState.error.isError, isTrue);
      expect(LoadingState.error.isBusy, isFalse);
      expect(LoadingState.error.canLoadMore, isFalse);
    });
  });
}

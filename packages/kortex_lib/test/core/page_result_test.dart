import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/core.dart';

void main() {
  group('PageResult', () {
    test('instantiates with unmodifiable items list and properties', () {
      final items = ['item1', 'item2'];
      final page = PageResult<String>(
        items: items,
        offset: 0,
        limit: 10,
        total: 50,
      );

      expect(page.items, equals(['item1', 'item2']));
      expect(page.offset, 0);
      expect(page.limit, 10);
      expect(page.total, 50);
      expect(page.length, 2);
      expect(page.isEmpty, isFalse);
      expect(page.isNotEmpty, isTrue);
      expect(page.hasMore, isTrue);

      // Verificação de imutabilidade profunda
      expect(
        () => (page.items as dynamic).add('item3'),
        throwsUnsupportedError,
      );
    });

    test('hasMore returns false when offset + items.length >= total', () {
      final page = PageResult<int>(
        items: const [1, 2, 3],
        offset: 7,
        limit: 5,
        total: 10,
      );

      expect(page.hasMore, isFalse);
    });

    test('structural equality and hashCode based on items and metadata', () {
      final page1 = PageResult<String>(
        items: const ['a', 'b'],
        offset: 0,
        limit: 10,
        total: 20,
      );
      final page2 = PageResult<String>(
        items: const ['a', 'b'],
        offset: 0,
        limit: 10,
        total: 20,
      );
      final pageDifferent = PageResult<String>(
        items: const ['a', 'c'],
        offset: 0,
        limit: 10,
        total: 20,
      );

      expect(page1, equals(page2));
      expect(page1.hashCode, equals(page2.hashCode));
      expect(page1, isNot(equals(pageDifferent)));
    });

    test('empty factory creates empty PageResult with zero total', () {
      final empty = PageResult<int>.empty();

      expect(empty.items, isEmpty);
      expect(empty.offset, 0);
      expect(empty.limit, 0);
      expect(empty.total, 0);
      expect(empty.hasMore, isFalse);
      expect(empty.isEmpty, isTrue);
    });
  });
}

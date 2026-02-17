import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/paper_provider.dart';

void main() {
  group('SearchParams', () {
    test('default values', () {
      const params = SearchParams(query: 'test');
      expect(params.query, 'test');
      expect(params.page, 1);
      expect(params.source, isNull);
      expect(params.yearFrom, isNull);
      expect(params.yearTo, isNull);
    });

    test('copyWith changes query', () {
      const params = SearchParams(query: 'old');
      final updated = params.copyWith(query: 'new');
      expect(updated.query, 'new');
      expect(updated.page, 1);
    });

    test('copyWith changes page', () {
      const params = SearchParams(query: 'q', page: 1);
      final updated = params.copyWith(page: 3);
      expect(updated.page, 3);
      expect(updated.query, 'q');
    });

    test('copyWith sets source', () {
      const params = SearchParams(query: 'q');
      final updated = params.copyWith(source: 'arxiv');
      expect(updated.source, 'arxiv');
    });

    test('copyWith clears source', () {
      const params = SearchParams(query: 'q', source: 'arxiv');
      final updated = params.copyWith(clearSource: true);
      expect(updated.source, isNull);
    });

    test('copyWith sets year range', () {
      const params = SearchParams(query: 'q');
      final updated = params.copyWith(yearFrom: 2020, yearTo: 2025);
      expect(updated.yearFrom, 2020);
      expect(updated.yearTo, 2025);
    });

    test('copyWith clears yearFrom', () {
      const params = SearchParams(query: 'q', yearFrom: 2020);
      final updated = params.copyWith(clearYearFrom: true);
      expect(updated.yearFrom, isNull);
    });

    test('copyWith clears yearTo', () {
      const params = SearchParams(query: 'q', yearTo: 2025);
      final updated = params.copyWith(clearYearTo: true);
      expect(updated.yearTo, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const params = SearchParams(
        query: 'q',
        page: 2,
        source: 'openalex',
        yearFrom: 2020,
        yearTo: 2025,
      );
      final updated = params.copyWith(page: 3);
      expect(updated.query, 'q');
      expect(updated.source, 'openalex');
      expect(updated.yearFrom, 2020);
      expect(updated.yearTo, 2025);
    });
  });
}

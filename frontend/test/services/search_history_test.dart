import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/search_history_service.dart';

void main() {
  group('SearchHistoryService', () {
    late SearchHistoryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = SearchHistoryService(prefs);
    });

    test('starts with empty history', () {
      expect(service.getHistory(), isEmpty);
    });

    test('addQuery adds to history', () async {
      await service.addQuery('quantum computing');
      expect(service.getHistory(), ['quantum computing']);
    });

    test('addQuery puts newest first', () async {
      await service.addQuery('first');
      await service.addQuery('second');
      expect(service.getHistory(), ['second', 'first']);
    });

    test('addQuery deduplicates (moves to top)', () async {
      await service.addQuery('a');
      await service.addQuery('b');
      await service.addQuery('a');
      expect(service.getHistory(), ['a', 'b']);
    });

    test('addQuery trims whitespace', () async {
      await service.addQuery('  hello  ');
      expect(service.getHistory(), ['hello']);
    });

    test('addQuery ignores empty strings', () async {
      await service.addQuery('');
      await service.addQuery('   ');
      expect(service.getHistory(), isEmpty);
    });

    test('addQuery limits to 20 items', () async {
      for (int i = 0; i < 25; i++) {
        await service.addQuery('query$i');
      }
      final history = service.getHistory();
      expect(history, hasLength(20));
      expect(history.first, 'query24');
      expect(history.last, 'query5');
    });

    test('removeQuery removes specific item', () async {
      await service.addQuery('a');
      await service.addQuery('b');
      await service.addQuery('c');
      await service.removeQuery('b');
      expect(service.getHistory(), ['c', 'a']);
    });

    test('removeQuery does nothing for non-existent item', () async {
      await service.addQuery('a');
      await service.removeQuery('z');
      expect(service.getHistory(), ['a']);
    });

    test('clear removes all history', () async {
      await service.addQuery('a');
      await service.addQuery('b');
      await service.clear();
      expect(service.getHistory(), isEmpty);
    });
  });
}

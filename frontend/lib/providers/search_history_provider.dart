import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
import '../services/search_history_service.dart';

final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return SearchHistoryService(prefs);
});

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);

class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.read(searchHistoryServiceProvider).getHistory();
  }

  Future<void> add(String query) async {
    await ref.read(searchHistoryServiceProvider).addQuery(query);
    state = ref.read(searchHistoryServiceProvider).getHistory();
  }

  Future<void> remove(String query) async {
    await ref.read(searchHistoryServiceProvider).removeQuery(query);
    state = ref.read(searchHistoryServiceProvider).getHistory();
  }

  Future<void> clear() async {
    await ref.read(searchHistoryServiceProvider).clear();
    state = [];
  }
}

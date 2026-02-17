import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'search_history';
const _maxItems = 20;

class SearchHistoryService {
  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  List<String> getHistory() {
    return _prefs.getStringList(_kKey) ?? [];
  }

  Future<void> addQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = getHistory()..remove(q);
    list.insert(0, q);
    if (list.length > _maxItems) list.removeRange(_maxItems, list.length);
    await _prefs.setStringList(_kKey, list);
  }

  Future<void> removeQuery(String query) async {
    final list = getHistory()..remove(query);
    await _prefs.setStringList(_kKey, list);
  }

  Future<void> clear() async {
    await _prefs.remove(_kKey);
  }
}

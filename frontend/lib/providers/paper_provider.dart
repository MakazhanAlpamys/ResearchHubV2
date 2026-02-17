import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paper.dart';
import '../services/paper_service.dart';

final paperServiceProvider = Provider<PaperService>((ref) => PaperService());

/// Search parameters holder.
class SearchParams {
  final String query;
  final int page;
  final String? source;
  final int? yearFrom;
  final int? yearTo;

  const SearchParams({
    required this.query,
    this.page = 1,
    this.source,
    this.yearFrom,
    this.yearTo,
  });

  SearchParams copyWith({
    String? query,
    int? page,
    String? source,
    int? yearFrom,
    int? yearTo,
    bool clearSource = false,
    bool clearYearFrom = false,
    bool clearYearTo = false,
  }) {
    return SearchParams(
      query: query ?? this.query,
      page: page ?? this.page,
      source: clearSource ? null : (source ?? this.source),
      yearFrom: clearYearFrom ? null : (yearFrom ?? this.yearFrom),
      yearTo: clearYearTo ? null : (yearTo ?? this.yearTo),
    );
  }
}

final searchParamsProvider =
    StateProvider<SearchParams?>((ref) => null);

final searchResultsProvider =
    FutureProvider<PaperSearchResult?>((ref) async {
  final params = ref.watch(searchParamsProvider);
  if (params == null || params.query.isEmpty) return null;

  final service = ref.read(paperServiceProvider);
  return service.searchPapers(
    query: params.query,
    page: params.page,
    source: params.source,
    yearFrom: params.yearFrom,
    yearTo: params.yearTo,
  );
});

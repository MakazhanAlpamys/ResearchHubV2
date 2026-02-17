import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../models/paper.dart';
import '../../providers/paper_provider.dart';
import '../../providers/search_history_provider.dart';
import '../../widgets/paper_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  // Filter state
  String? _source;
  int? _yearFrom;
  int? _yearTo;

  // Pagination
  final List<Paper> _allPapers = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  // Source statuses from latest first-page result
  List<SourceStatus> _sourceStatuses = [];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Save to history
    ref.read(searchHistoryProvider.notifier).add(query);

    _allPapers.clear();
    _currentPage = 1;
    _hasMore = true;
    _sourceStatuses = [];
    _focusNode.unfocus();

    ref.read(searchParamsProvider.notifier).state = SearchParams(
      query: query,
      page: 1,
      source: _source,
      yearFrom: _yearFrom,
      yearTo: _yearTo,
    );
  }

  Future<void> _refresh() async {
    if (_searchController.text.trim().isEmpty) return;
    _performSearch();
    // Wait for the provider to resolve
    await ref.read(searchResultsProvider.future);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final service = ref.read(paperServiceProvider);
      final result = await service.searchPapers(
        query: _searchController.text.trim(),
        page: _currentPage + 1,
        source: _source,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
      );
      setState(() {
        _currentPage++;
        _allPapers.addAll(result.papers);
        _hasMore = result.hasMore && result.papers.isNotEmpty;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final results = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: () => _showFilters(context),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          // Active filter chips
          _buildFilterChips(l10n),
          // Source status bar
          if (_sourceStatuses.any((s) => !s.ok))
            _buildSourceStatusBar(l10n, theme),
          const Divider(height: 1),
          // Results or history
          Expanded(
            child: results.when(
              data: (data) {
                if (data == null) {
                  // Show search history when no search performed
                  if (history.isNotEmpty &&
                      _searchController.text.trim().isEmpty) {
                    return _buildHistoryList(history, l10n, theme);
                  }
                  return _buildEmptyState(theme, l10n);
                }
                // Update source statuses from first-page data
                if (_currentPage == 1 && data.sources.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _sourceStatuses = data.sources);
                    }
                  });
                }
                // Merge first-page results with subsequent loaded pages
                final papers = [...data.papers, ..._allPapers];
                if (papers.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noResults,
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }
                final showLoadMore =
                    _currentPage == 1 ? data.hasMore : _hasMore;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: papers.length + (showLoadMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i < papers.length) {
                        return PaperCard(paper: papers[i]);
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: _loadingMore
                            ? const Center(child: CircularProgressIndicator())
                            : OutlinedButton(
                                onPressed: _loadMore,
                                child: Text(l10n.loadMore),
                              ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(l10n.error, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: _performSearch,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
      List<String> history, AppLocalizations l10n, ThemeData theme) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(l10n.recentSearches,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clear(),
                child: Text(l10n.clearHistory),
              ),
            ],
          ),
        ),
        for (final query in history)
          ListTile(
            leading: const Icon(Icons.history, size: 20),
            title: Text(query),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).remove(query),
            ),
            onTap: () {
              _searchController.text = query;
              _performSearch();
            },
          ),
      ],
    );
  }

  Widget _buildSourceStatusBar(AppLocalizations l10n, ThemeData theme) {
    final failed =
        _sourceStatuses.where((s) => !s.ok).map((s) => s.name).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${failed.join(", ")} — ${l10n.sourceUnavailable}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search,
              size: 80, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            l10n.searchHint,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final chips = <Widget>[];

    if (_source != null) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InputChip(
          label: Text(_source!),
          onDeleted: () {
            setState(() => _source = null);
            if (_searchController.text.isNotEmpty) _performSearch();
          },
        ),
      ));
    }
    if (_yearFrom != null || _yearTo != null) {
      final label = '${_yearFrom ?? '…'} – ${_yearTo ?? '…'}';
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InputChip(
          label: Text(label),
          onDeleted: () {
            setState(() {
              _yearFrom = null;
              _yearTo = null;
            });
            if (_searchController.text.isNotEmpty) _performSearch();
          },
        ),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: chips),
    );
  }

  void _showFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? tempSource = _source;
    final yearFromCtrl =
        TextEditingController(text: _yearFrom?.toString() ?? '');
    final yearToCtrl =
        TextEditingController(text: _yearTo?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.filters,
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),
                Text(l10n.source,
                    style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.allSources),
                      selected: tempSource == null,
                      onSelected: (_) =>
                          setModalState(() => tempSource = null),
                    ),
                    for (final src in [
                      'arxiv',
                      'openalex',
                      'semantic_scholar'
                    ])
                      ChoiceChip(
                        label: Text(src),
                        selected: tempSource == src,
                        onSelected: (_) =>
                            setModalState(() => tempSource = src),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: yearFromCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: l10n.yearFrom),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: yearToCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: l10n.yearTo),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _source = tempSource;
                      _yearFrom = int.tryParse(yearFromCtrl.text);
                      _yearTo = int.tryParse(yearToCtrl.text);
                    });
                    Navigator.pop(ctx);
                    if (_searchController.text.isNotEmpty) _performSearch();
                  },
                  child: Text(l10n.apply),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

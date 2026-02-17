import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../models/paper.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/paper_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  Future<void> _refresh() async {
    ref.invalidate(favoritesProvider);
    ref.invalidate(collectionsProvider);
    await ref.read(favoritesProvider.future);
  }

  void _showCreateCollectionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newCollection),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.collectionName),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(collectionsProvider.notifier).create(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final favState = ref.watch(favoritesProvider);
    final collectionsState = ref.watch(collectionsProvider);
    final selectedCollection = ref.watch(selectedCollectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: l10n.newCollection,
            onPressed: () => _showCreateCollectionDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Collection filter chips
          collectionsState.when(
            data: (collections) {
              if (collections.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(l10n.allFavorites),
                        selected: selectedCollection == null,
                        onSelected: (_) => ref
                            .read(selectedCollectionProvider.notifier)
                            .state = null,
                      ),
                    ),
                    for (final col in collections)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(col.name),
                          selected: selectedCollection == col.id,
                          onSelected: (_) => ref
                              .read(selectedCollectionProvider.notifier)
                              .state = col.id,
                          onDeleted: () => _confirmDeleteCollection(col),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Favorites list
          Expanded(
            child: favState.when(
              data: (papers) {
                if (papers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border,
                            size: 80,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text(l10n.noFavorites,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: papers.length,
                    itemBuilder: (context, i) =>
                        PaperCard(paper: papers[i]),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(l10n.error, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(favoritesProvider),
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

  void _confirmDeleteCollection(PaperCollection collection) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.delete} "${collection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(collectionsProvider.notifier)
                  .delete(collection.id);
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

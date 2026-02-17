import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paper.dart';
import '../services/favorites_service.dart';

final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());

/// Currently selected collection filter (null = all favorites).
final selectedCollectionProvider =
    StateProvider<String?>((ref) => null);

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Paper>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<List<Paper>> {
  @override
  Future<List<Paper>> build() async {
    final service = ref.read(favoritesServiceProvider);
    final collectionId = ref.watch(selectedCollectionProvider);
    return service.getFavorites(collectionId: collectionId);
  }

  Future<void> add(Paper paper, {String? collectionId}) async {
    final service = ref.read(favoritesServiceProvider);
    await service.addFavorite(paper, collectionId: collectionId);
    ref.invalidateSelf();
  }

  Future<void> remove(String paperId) async {
    final service = ref.read(favoritesServiceProvider);
    await service.removeFavorite(paperId);
    ref.invalidateSelf();
  }

  Future<void> moveToCollection(String paperId, String? collectionId) async {
    final service = ref.read(favoritesServiceProvider);
    await service.moveToCollection(paperId, collectionId);
    ref.invalidateSelf();
  }

  bool isFavorite(String paperId) {
    final papers = state.valueOrNull ?? [];
    return papers.any((p) => p.paperId == paperId);
  }
}

final collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<PaperCollection>>(
  CollectionsNotifier.new,
);

class CollectionsNotifier extends AsyncNotifier<List<PaperCollection>> {
  @override
  Future<List<PaperCollection>> build() async {
    final service = ref.read(favoritesServiceProvider);
    return service.getCollections();
  }

  Future<void> create(String name) async {
    final service = ref.read(favoritesServiceProvider);
    await service.createCollection(name);
    ref.invalidateSelf();
  }

  Future<void> delete(String collectionId) async {
    final service = ref.read(favoritesServiceProvider);
    await service.deleteCollection(collectionId);
    ref.invalidateSelf();
    // Reset selection if the deleted collection was selected
    final selected = ref.read(selectedCollectionProvider);
    if (selected == collectionId) {
      ref.read(selectedCollectionProvider.notifier).state = null;
    }
  }
}

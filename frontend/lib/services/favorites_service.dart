import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/paper.dart';

class FavoritesService {
  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<Paper>> getFavorites({String? collectionId}) async {
    final userId = _userId;
    if (userId == null) return [];

    var query = _supabase
        .from('favorites')
        .select()
        .eq('user_id', userId);

    if (collectionId != null) {
      query = query.eq('collection_id', collectionId);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Paper.fromFavoriteRow(e)).toList();
  }

  Future<void> addFavorite(Paper paper, {String? collectionId}) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    // Check if already exists to avoid 409 Conflict from PostgREST upsert
    final existing = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('paper_id', paper.paperId)
        .maybeSingle();

    if (existing != null) {
      // Update existing favorite
      final updates = <String, dynamic>{
        'title': paper.title,
        'authors': paper.authors,
        'abstract': paper.abstract_,
        'published_date': paper.publishedDate,
        'source': paper.source,
        'url': paper.url,
        'pdf_url': paper.pdfUrl,
        'collection_id': collectionId,
      };
      await _supabase
          .from('favorites')
          .update(updates)
          .eq('user_id', userId)
          .eq('paper_id', paper.paperId);
    } else {
      // Insert new favorite
      await _supabase
          .from('favorites')
          .insert(paper.toFavoriteRow(userId, collectionId: collectionId));
    }
  }

  Future<void> removeFavorite(String paperId) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('paper_id', paperId);
  }

  Future<void> moveToCollection(String paperId, String? collectionId) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    await _supabase
        .from('favorites')
        .update({'collection_id': collectionId})
        .eq('user_id', userId)
        .eq('paper_id', paperId);
  }

  Future<bool> isFavorite(String paperId) async {
    final userId = _userId;
    if (userId == null) return false;

    final data = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('paper_id', paperId)
        .maybeSingle();
    return data != null;
  }

  // ── Collections ──────────────────────────────────

  Future<List<PaperCollection>> getCollections() async {
    final userId = _userId;
    if (userId == null) return [];

    final data = await _supabase
        .from('collections')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (data as List).map((e) => PaperCollection.fromJson(e)).toList();
  }

  Future<PaperCollection> createCollection(String name) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    // Check if collection with same name already exists
    final existing = await _supabase
        .from('collections')
        .select()
        .eq('user_id', userId)
        .eq('name', name)
        .maybeSingle();

    if (existing != null) {
      return PaperCollection.fromJson(existing);
    }

    final data = await _supabase
        .from('collections')
        .insert({'user_id': userId, 'name': name})
        .select()
        .single();

    return PaperCollection.fromJson(data);
  }

  Future<void> deleteCollection(String collectionId) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    // Unlink favorites first
    await _supabase
        .from('favorites')
        .update({'collection_id': null})
        .eq('user_id', userId)
        .eq('collection_id', collectionId);

    await _supabase
        .from('collections')
        .delete()
        .eq('id', collectionId)
        .eq('user_id', userId);
  }
}

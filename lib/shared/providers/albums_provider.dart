import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album.dart';
import '../models/review.dart';
import '../recommender/recommender.dart';

final catalogProvider = FutureProvider<List<Album>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/catalog.json');
  final albums = (json.decode(raw)['albums'] as List).cast<Map<String, dynamic>>();
  return albums.map(Album.fromCatalog).toList();
});

final recommenderProvider = FutureProvider<Recommender>((ref) async {
  return Recommender(await ref.watch(catalogProvider.future));
});

final albumByIdProvider = Provider.family<Album?, String>((ref, id) {
  return ref.watch(recommenderProvider).valueOrNull?.byId[id];
});

/// Bayesian average of MusicBrainz community ratings, so 1 vote of 5★ does not beat 40 votes of 4.6★.
final communityFavoritesProvider = FutureProvider<List<Album>>((ref) async {
  final albums = await ref.watch(catalogProvider.future);
  final rated = albums.where((a) => a.avgRating != null).toList();
  if (rated.isEmpty) return albums.take(12).toList();
  final mean = rated.map((a) => a.avgRating!).reduce((a, b) => a + b) / rated.length;
  const m = 5;
  double score(Album a) => (a.ratingCount * a.avgRating! + m * mean) / (a.ratingCount + m);
  rated.sort((a, b) => score(b).compareTo(score(a)));
  return rated.take(12).toList();
});

final starterAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final albums = await ref.watch(catalogProvider.future);
  final sorted = [...albums]..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
  final seen = <String>{};
  return sorted.where((a) => seen.add(a.artist)).take(16).toList();
});

final topTagsProvider = FutureProvider<List<String>>((ref) async {
  final rec = await ref.watch(recommenderProvider.future);
  final counts = <String, int>{};
  for (final a in rec.albums) {
    for (final t in a.tags.keys.take(4)) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  final tags = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return tags.take(16).map((e) => e.key).toList();
});

class RatingsNotifier extends StateNotifier<Map<String, double>> {
  static const _key = 'cadence.ratings';

  RatingsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final stored = (json.decode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
    state = {...stored, ...state};
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state));
  }

  void rate(String albumId, double rating) {
    state = {...state, albumId: rating};
    _save();
  }

  void remove(String albumId) {
    state = {...state}..remove(albumId);
    _save();
  }

  void clear() {
    state = {};
    _save();
  }
}

final ratingsProvider = StateNotifierProvider<RatingsNotifier, Map<String, double>>((ref) => RatingsNotifier());

final recommendationsProvider = Provider<AsyncValue<List<Recommendation>>>((ref) {
  final ratings = ref.watch(ratingsProvider);
  return ref.watch(recommenderProvider).whenData((r) => r.recommend(ratings));
});

final deepCutsProvider = Provider<AsyncValue<List<Recommendation>>>((ref) {
  final ratings = ref.watch(ratingsProvider);
  return ref.watch(recommenderProvider).whenData((r) {
    final counts = r.albums.map((a) => a.ratingCount).toList()..sort();
    final median = counts.isEmpty ? 0 : counts[counts.length ~/ 2];
    final shown = r.recommend(ratings).map((x) => x.album.id).toSet();
    return r.recommend(ratings, k: 10, where: (a) => a.ratingCount <= median && !shown.contains(a.id));
  });
});

final similarAlbumsProvider = Provider.family<List<MapEntry<Album, double>>, String>((ref, albumId) {
  final rec = ref.watch(recommenderProvider).valueOrNull;
  final album = rec?.byId[albumId];
  if (rec == null || album == null) return [];
  return rec.similarTo(album, k: 10);
});

final explanationProvider = Provider.family<Explanation?, String>((ref, albumId) {
  final ratings = ref.watch(ratingsProvider);
  final rec = ref.watch(recommenderProvider).valueOrNull;
  final album = rec?.byId[albumId];
  if (rec == null || album == null || ratings.isEmpty || ratings.containsKey(albumId)) return null;
  final why = rec.explain(album, ratings);
  return why.tags.isEmpty && why.because.isEmpty ? null : why;
});

final albumSearchProvider = StateNotifierProvider<AlbumSearchNotifier, AsyncValue<List<Album>>>((ref) {
  return AlbumSearchNotifier(ref);
});

class AlbumSearchNotifier extends StateNotifier<AsyncValue<List<Album>>> {
  final Ref _ref;
  AlbumSearchNotifier(this._ref) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    final albums = await _ref.read(catalogProvider.future);
    int rank(Album a) {
      if (a.title.toLowerCase().contains(q)) return 0;
      if (a.artist.toLowerCase().contains(q)) return 1;
      if (a.tags.keys.any((t) => t.contains(q))) return 2;
      return 3;
    }

    final results = albums.where((a) => rank(a) < 3).toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return (b.tags[q] ?? 0).compareTo(a.tags[q] ?? 0);
      });
    state = AsyncValue.data(results);
  }

  void clear() => state = const AsyncValue.data([]);
}

class ReviewsNotifier extends StateNotifier<List<Review>> {
  ReviewsNotifier() : super(const []);

  void addReview(Review review) => state = [review, ...state];
}

final reviewsProvider = StateNotifierProvider<ReviewsNotifier, List<Review>>((ref) => ReviewsNotifier());

final albumReviewsProvider = Provider.family<List<Review>, String>((ref, albumId) {
  return ref.watch(reviewsProvider).where((r) => r.albumId == albumId).toList();
});

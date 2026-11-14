import 'dart:math';
import '../models/album.dart';

typedef SparseVector = Map<String, double>;

class Influence {
  final Album album;
  final double rating;
  final double weight;
  const Influence(this.album, this.rating, this.weight);
}

class Explanation {
  final List<MapEntry<String, double>> tags;
  final List<Influence> because;
  final bool sameArtist;
  const Explanation({this.tags = const [], this.because = const [], this.sameArtist = false});

  String get short {
    if (because.isNotEmpty) return 'Because you rated ${because.first.album.title}';
    if (tags.isNotEmpty) return tags.take(2).map((e) => e.key).join(' · ');
    return '';
  }
}

class Recommendation {
  final Album album;
  final double score;
  final Explanation why;
  const Recommendation(this.album, this.score, this.why);
}

/// Content-based recommender: TF-IDF over community tags, user profile built
/// from centred ratings (Rocchio), diversified with MMR.
class Recommender {
  static const _artistWeight = 2.0;

  final List<Album> albums;
  final Map<String, Album> byId;
  final Map<String, double> idf = {};
  final Map<String, SparseVector> _vectors = {};

  Recommender(this.albums) : byId = {for (final a in albums) a.id: a} {
    final df = <String, int>{};
    for (final a in albums) {
      for (final t in a.tags.keys) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }
    final n = albums.length;
    df.forEach((t, d) => idf[t] = log((1 + n) / (1 + d)) + 1);

    for (final a in albums) {
      final maxCount = a.tags.values.fold<double>(1, max);
      final v = <String, double>{
        for (final e in a.tags.entries) e.key: (e.value / maxCount) * idf[e.key]!,
        _artistKey(a): _artistWeight,
      };
      _vectors[a.id] = _normalize(v);
    }
  }

  static String _artistKey(Album a) => 'artist:${a.artist.toLowerCase()}';

  static double ratingWeight(double rating) => (rating - 2.75) / 2.25;

  double similarity(Album a, Album b) => _dot(_vectors[a.id]!, _vectors[b.id]!);

  List<MapEntry<Album, double>> similarTo(Album album, {int k = 10}) {
    final v = _vectors[album.id];
    if (v == null) return [];
    final scored = albums
        .where((a) => a.id != album.id)
        .map((a) => MapEntry(a, _dot(v, _vectors[a.id]!)))
        .toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    return scored.take(k).toList();
  }

  SparseVector profile(Map<String, double> ratings) {
    final p = <String, double>{};
    ratings.forEach((id, r) {
      final v = _vectors[id];
      if (v == null) return;
      final w = ratingWeight(r);
      v.forEach((t, x) => p[t] = (p[t] ?? 0) + w * x);
    });
    return p;
  }

  List<Recommendation> recommend(
    Map<String, double> ratings, {
    int k = 12,
    double lambda = 0.7,
    bool Function(Album)? where,
  }) {
    final p = profile(ratings);
    final norm = _norm(p);
    if (norm == 0) return [];

    final pool = albums
        .where((a) => !ratings.containsKey(a.id) && (where?.call(a) ?? true))
        .map((a) => MapEntry(a, _dot(p, _vectors[a.id]!) / norm))
        .where((e) => e.value > 0)
        .toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    final candidates = pool.take(80).toList();

    final picked = <MapEntry<Album, double>>[];
    while (picked.length < k && candidates.isNotEmpty) {
      var bestIndex = 0;
      var bestValue = double.negativeInfinity;
      for (var i = 0; i < candidates.length; i++) {
        final c = candidates[i];
        final redundancy = picked.isEmpty ? 0.0 : picked.map((s) => similarity(c.key, s.key)).reduce(max);
        final value = lambda * c.value - (1 - lambda) * redundancy;
        if (value > bestValue) {
          bestValue = value;
          bestIndex = i;
        }
      }
      picked.add(candidates.removeAt(bestIndex));
    }

    return picked.map((e) => Recommendation(e.key, e.value, explain(e.key, ratings, p))).toList();
  }

  Explanation explain(Album album, Map<String, double> ratings, [SparseVector? userProfile]) {
    final p = userProfile ?? profile(ratings);
    final v = _vectors[album.id]!;

    final tagContrib = <MapEntry<String, double>>[];
    var sameArtist = false;
    v.forEach((t, x) {
      final c = (p[t] ?? 0) * x;
      if (c <= 0) return;
      if (t.startsWith('artist:')) {
        sameArtist = true;
      } else {
        tagContrib.add(MapEntry(t, c));
      }
    });
    tagContrib.sort((a, b) => b.value.compareTo(a.value));

    final because = <Influence>[];
    ratings.forEach((id, r) {
      final rated = byId[id];
      if (rated == null || id == album.id) return;
      final w = ratingWeight(r) * similarity(rated, album);
      if (w > 0) because.add(Influence(rated, r, w));
    });
    because.sort((a, b) => b.weight.compareTo(a.weight));

    return Explanation(tags: tagContrib.take(5).toList(), because: because.take(3).toList(), sameArtist: sameArtist);
  }

  List<MapEntry<String, double>> tasteProfile(Map<String, double> ratings, {int k = 6}) {
    final entries = profile(ratings).entries.where((e) => !e.key.startsWith('artist:') && e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return [];
    final top = entries.first.value;
    return entries.take(k).map((e) => MapEntry(e.key, e.value / top)).toList();
  }

  static double _dot(SparseVector a, SparseVector b) {
    final (small, large) = a.length <= b.length ? (a, b) : (b, a);
    var s = 0.0;
    small.forEach((k, x) {
      final y = large[k];
      if (y != null) s += x * y;
    });
    return s;
  }

  static double _norm(SparseVector v) => sqrt(v.values.fold<double>(0, (s, x) => s + x * x));

  static SparseVector _normalize(SparseVector v) {
    final n = _norm(v);
    return n == 0 ? v : v.map((k, x) => MapEntry(k, x / n));
  }
}

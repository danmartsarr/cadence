class Album {
  final String id;
  final String title;
  final String artist;
  final String? coverUrl;
  final int? year;
  final Map<String, double> tags;
  final double? avgRating;
  final int ratingCount;
  final List<Track> tracks;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.year,
    this.tags = const {},
    this.avgRating,
    this.ratingCount = 0,
    this.tracks = const [],
  });

  List<String> get genres => tags.keys.take(3).toList();

  factory Album.fromCatalog(Map<String, dynamic> json) {
    final tracks = (json['tracks'] as List? ?? []).asMap().entries.map((e) {
      final t = e.value as Map<String, dynamic>;
      return Track(id: '${json['id']}_${e.key}', title: t['title'] ?? '', durationMs: t['ms'], position: e.key + 1);
    }).toList();

    return Album(
      id: json['id'],
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      coverUrl: json['cover'],
      year: json['year'],
      tags: (json['tags'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      avgRating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['votes'] ?? 0,
      tracks: tracks,
    );
  }
}

class Track {
  final String id;
  final String title;
  final int? durationMs;
  final int position;

  const Track({required this.id, required this.title, this.durationMs, required this.position});

  String get formattedDuration {
    if (durationMs == null) return '';
    final secs = durationMs! ~/ 1000;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }
}

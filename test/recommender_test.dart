import 'package:cadence/shared/models/album.dart';
import 'package:cadence/shared/recommender/recommender.dart';
import 'package:flutter_test/flutter_test.dart';

Album _a(String id, String artist, Map<String, double> tags) => Album(id: id, title: id, artist: artist, tags: tags);

void main() {
  final albums = [
    _a('rock1', 'A', {'rock': 10, 'guitar': 5}),
    _a('rock2', 'B', {'rock': 8, 'guitar': 6}),
    _a('jazz1', 'C', {'jazz': 10, 'saxophone': 5}),
    _a('jazz2', 'D', {'jazz': 9, 'saxophone': 4, 'bebop': 2}),
    _a('mix', 'E', {'rock': 3, 'jazz': 3}),
  ];
  final rec = Recommender(albums);

  test('similar albums share tags', () {
    final top = rec.similarTo(albums[0], k: 1).first.key;
    expect(top.id, 'rock2');
  });

  test('a loved rock album yields rock recommendations, not jazz', () {
    final recs = rec.recommend({'rock1': 5.0}, k: 2);
    expect(recs.first.album.id, 'rock2');
    expect(recs.map((r) => r.album.id), isNot(contains('jazz1')));
  });

  test('a low rating pushes similar albums away', () {
    final recs = rec.recommend({'jazz1': 5.0, 'rock1': 0.5}, k: 3);
    expect(recs.first.album.id, 'jazz2');
    expect(recs.map((r) => r.album.id), isNot(contains('rock2')));
  });

  test('explanation cites the rated album and the shared tag', () {
    final why = rec.explain(albums[1], {'rock1': 5.0});
    expect(why.because.first.album.id, 'rock1');
    expect(why.tags.map((e) => e.key), contains('rock'));
  });

  test('rated albums are never recommended again', () {
    final recs = rec.recommend({'rock1': 5.0, 'rock2': 4.5});
    expect(recs.map((r) => r.album.id), isNot(anyOf(contains('rock1'), contains('rock2'))));
  });
}

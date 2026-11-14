import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/album.dart';
import '../../../shared/providers/albums_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/recommender/recommender.dart';
import '../../../shared/widgets/album_cover.dart';
import '../../../shared/widgets/poster.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final ratings = ref.watch(ratingsProvider);
    final forYou = ref.watch(recommendationsProvider);
    final deepCuts = ref.watch(deepCutsProvider);
    final favorites = ref.watch(communityFavoritesProvider);
    final starters = ref.watch(starterAlbumsProvider);
    final taste = ref.watch(tasteProvider);
    final hasTaste = ratings.length >= 3;
    final name = user?.username ?? 'there';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: CadenceColors.background.withAlpha(235),
            titleSpacing: 20,
            title: Row(children: [
              const CadenceMark(size: 26),
              const SizedBox(width: 10),
              Text('cadence', style: CadenceType.display(24)),
            ]),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: CadenceColors.accent,
                    child: Text(name.isEmpty ? 'U' : name[0].toUpperCase(),
                        style: CadenceType.ui(13, weight: FontWeight.w800, color: CadenceColors.onPrimary)),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good ${_greeting()},\n$name.', style: CadenceType.display(38)),
                const SizedBox(height: 10),
                hasTaste
                    ? Text('${ratings.length} albums rated. Here is what we think you\'ll love next.',
                        style: CadenceType.ui(14.5, weight: FontWeight.w400, color: CadenceColors.textSecondary))
                    : _Progress(count: ratings.length),
              ]),
            ),
          ),

          if (!hasTaste)
            _Row(
              eyebrow: 'Start here',
              title: 'Rate a few you know',
              subtitle: 'Open an album and tap the stars. Every rating teaches the model.',
              height: 196,
              child: starters.when(
                loading: () => const _ShimmerRow(),
                error: (e, _) => const _ErrorRow(),
                data: (albums) => _horizontal([
                  for (final a in albums)
                    ratings[a.id] != null
                        ? PosterTile(album: a, stars: ratings[a.id])
                        : PosterTile(album: a),
                ]),
              ),
            ),

          if (hasTaste) ...[
            _Row(
              eyebrow: 'Made for you',
              title: 'Picked for your ears',
              height: 362,
              child: forYou.when(
                loading: () => const _ShimmerRow(size: 260),
                error: (e, _) => const _ErrorRow(),
                data: (recs) => _horizontal([for (final r in recs) _HeroCard(rec: r)], gap: 14),
              ),
            ),
            if (taste.isNotEmpty)
              _Row(
                title: 'Your sound',
                subtitle: 'What your ratings have in common',
                height: 208,
                child: _TasteGrid(taste: taste),
              ),
            _Row(
              title: 'Deep cuts',
              subtitle: 'Same taste, fewer people listening',
              height: 196,
              child: deepCuts.when(
                loading: () => const _ShimmerRow(),
                error: (e, _) => const _ErrorRow(),
                data: (recs) => _horizontal([for (final r in recs) PosterTile(album: r.album, caption: r.album.artist)]),
              ),
            ),
          ],

          _Row(
            title: 'Highest rated',
            subtitle: 'By the MusicBrainz community',
            height: 196,
            child: favorites.when(
              loading: () => const _ShimmerRow(),
              error: (e, _) => const _ErrorRow(),
              data: (albums) => _horizontal([for (final a in albums) PosterTile(album: a, stars: a.avgRating)]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 40),
              child: Text('Recommendations are computed on your device from MusicBrainz tags.',
                  style: CadenceType.ui(12, weight: FontWeight.w400, color: CadenceColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 18) return 'afternoon';
    return 'evening';
  }
}

Widget _horizontal(List<Widget> children, {double gap = 16}) {
  return ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    scrollDirection: Axis.horizontal,
    itemCount: children.length,
    separatorBuilder: (_, _) => SizedBox(width: gap),
    itemBuilder: (_, i) => children[i],
  );
}

class _Row extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final double height;
  final Widget child;
  const _Row({required this.title, this.subtitle, this.eyebrow, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 34),
        SectionHeader(title: title, subtitle: subtitle, eyebrow: eyebrow),
        const SizedBox(height: 16),
        SizedBox(height: height, child: child),
      ]),
    );
  }
}

class _Progress extends StatelessWidget {
  final int count;
  const _Progress({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 28,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: i < count ? CadenceColors.primary : CadenceColors.surfaceElevated,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      const SizedBox(width: 8),
      Text('Rate ${3 - count} more to unlock your picks',
          style: CadenceType.ui(13.5, weight: FontWeight.w500, color: CadenceColors.textSecondary)),
    ]);
  }
}

/// Large cover card for a recommendation, with the reason written out.
class _HeroCard extends StatelessWidget {
  final Recommendation rec;
  const _HeroCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final a = rec.album;
    final because = rec.why.because.isNotEmpty ? rec.why.because.first.album : null;
    return GestureDetector(
      onTap: () => context.push('/album/${a.id}', extra: a),
      child: SizedBox(
        width: 260,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            PosterCover(album: a, size: 260, radius: 8),
            Positioned(left: 12, top: 12, child: MatchPill(score: rec.score)),
          ]),
          const SizedBox(height: 12),
          Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.display(22)),
          const SizedBox(height: 2),
          Text(a.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.ui(13.5, weight: FontWeight.w500, color: CadenceColors.textSecondary)),
          const SizedBox(height: 8),
          if (because != null)
            Row(children: [
              AlbumCover(url: because.coverUrl, width: 18, height: 18, borderRadius: 3),
              const SizedBox(width: 7),
              Expanded(
                child: Text('Because you loved ${because.title}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.ui(12, weight: FontWeight.w600, color: CadenceColors.primaryLight)),
              ),
            ])
          else if (rec.why.tags.isNotEmpty)
            Text(rec.why.tags.take(2).map((e) => e.key).join(' · '),
                style: CadenceType.ui(12, weight: FontWeight.w600, color: CadenceColors.primaryLight)),
        ]),
      ),
    );
  }
}

class _TasteGrid extends ConsumerWidget {
  final List<(String, double, Album?)> taste;
  const _TasteGrid({required this.taste});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairs = <List<(String, double, Album?)>>[];
    for (var i = 0; i < taste.length; i += 2) {
      pairs.add(taste.sublist(i, (i + 2).clamp(0, taste.length)));
    }
    return _horizontal([
      for (final p in pairs)
        Column(children: [
          for (final (tag, _, album) in p)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GenreTile(
                label: tag,
                cover: album,
                onTap: () {
                  ref.read(albumSearchProvider.notifier).search(tag);
                  context.go('/search?q=${Uri.encodeComponent(tag)}');
                },
              ),
            ),
        ]),
    ], gap: 12);
  }
}

class _ShimmerRow extends StatelessWidget {
  final double size;
  const _ShimmerRow({this.size = 140});

  @override
  Widget build(BuildContext context) {
    return _horizontal([
      for (var i = 0; i < 4; i++)
        Shimmer.fromColors(
          baseColor: CadenceColors.surface,
          highlightColor: CadenceColors.surfaceElevated,
          child: Container(width: size, height: size, decoration: BoxDecoration(color: CadenceColors.surface, borderRadius: BorderRadius.circular(6))),
        ),
    ]);
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow();

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Could not load the catalog', style: Theme.of(context).textTheme.bodySmall));
  }
}

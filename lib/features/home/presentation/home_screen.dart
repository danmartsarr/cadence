import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/album.dart';
import '../../../shared/providers/albums_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/album_cover.dart';

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
    final hasTaste = ratings.length >= 3;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: CadenceColors.background,
            title: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(gradient: CadenceColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.album, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('cadence', style: TextStyle(color: CadenceColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: CadenceColors.primary,
                  child: Text(
                    (user?.username.isNotEmpty ?? false) ? user!.username.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_greeting()}, ${user?.username ?? 'there'}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasTaste
                        ? 'Picked from ${ratings.length} ratings · tap a card to see why'
                        : 'Rate ${3 - ratings.length} more album${3 - ratings.length == 1 ? '' : 's'} to unlock your recommendations',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          if (!hasTaste)
            _Section(
              title: 'Start here',
              subtitle: 'Tap an album and rate it, the model learns from every star',
              height: 180,
              child: starters.when(
                loading: () => _ShimmerCarousel(height: 180),
                error: (err, stack) => const _ErrorCard(),
                data: (albums) => _AlbumCarousel(items: [for (final a in albums) (a, ratings[a.id] != null ? 'Rated ${ratings[a.id]!.toStringAsFixed(1)}★' : a.artist)]),
              ),
            ),

          if (hasTaste) ...[
            _Section(
              title: 'For you',
              subtitle: 'Content-based · diversified with MMR',
              height: 200,
              child: forYou.when(
                loading: () => _ShimmerCarousel(),
                error: (err, stack) => const _ErrorCard(),
                data: (recs) => _HeroCarousel(items: [for (final r in recs) (r.album, r.why.short, r.score)]),
              ),
            ),
            _Section(
              title: 'Deep cuts',
              subtitle: 'Same taste, less-voted albums',
              height: 180,
              child: deepCuts.when(
                loading: () => _ShimmerCarousel(height: 180),
                error: (err, stack) => const _ErrorCard(),
                data: (recs) => _AlbumCarousel(items: [for (final r in recs) (r.album, r.why.short.isEmpty ? r.album.artist : r.why.short)]),
              ),
            ),
          ],

          _Section(
            title: 'Community favorites',
            subtitle: 'MusicBrainz ratings, Bayesian average',
            height: 180,
            child: favorites.when(
              loading: () => _ShimmerCarousel(height: 180),
              error: (err, stack) => const _ErrorCard(),
              data: (albums) => _AlbumCarousel(items: [for (final a in albums) (a, '${a.avgRating?.toStringAsFixed(2) ?? '-'}★ · ${a.ratingCount} votes')]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  final Widget child;
  const _Section({required this.title, required this.subtitle, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 14),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  final List<(Album, String, double)> items;

  const _HeroCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 8),
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final (album, reason, score) = items[i];
        return GestureDetector(
          onTap: () => context.push('/album/${album.id}', extra: album),
          child: Container(
            width: 300,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AlbumCover(url: album.coverUrl, borderRadius: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.4, 1.0],
                      colors: [Colors.transparent, Color(0xEE050A14)],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album.artist,
                        style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          reason,
                          style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CadenceColors.primary.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(score * 100).round()}% match',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _AlbumCarousel extends StatelessWidget {
  final List<(Album, String)> items;

  const _AlbumCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 8),
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final (album, caption) = items[i];
        return GestureDetector(
          onTap: () => context.push('/album/${album.id}', extra: album),
          child: Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AlbumCover(url: album.coverUrl, width: 130, borderRadius: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  album.title,
                  style: const TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  caption,
                  style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerCarousel extends StatelessWidget {
  final double height;
  const _ShimmerCarousel({this.height = 200});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20),
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: CadenceColors.surface,
        highlightColor: CadenceColors.surfaceElevated,
        child: Container(
          width: height == 200 ? 300 : 130,
          height: height,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: CadenceColors.surface, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: CadenceColors.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text('Could not load the catalog', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

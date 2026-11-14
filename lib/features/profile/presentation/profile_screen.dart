import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/album.dart';
import '../../../shared/models/review.dart';
import '../../../shared/providers/albums_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/album_cover.dart';
import '../../../shared/widgets/poster.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final ratings = ref.watch(ratingsProvider);
    final rec = ref.watch(recommenderProvider).valueOrNull;
    final taste = ref.watch(tasteProvider);
    final myReviews = ref.watch(reviewsProvider).where((r) => r.userId == user.id).toList();
    final rated = <(Album, double)>[
      for (final e in ratings.entries)
        if (rec?.byId[e.key] != null) (rec!.byId[e.key]!, e.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final avg = ratings.isEmpty ? 0.0 : ratings.values.reduce((a, b) => a + b) / ratings.length;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: CadenceColors.background.withAlpha(235),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded, color: CadenceColors.textSecondary),
              onPressed: () => _showSettingsSheet(context, ref),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: CadenceColors.accent,
                  child: Text(user.username.isEmpty ? 'U' : user.username[0].toUpperCase(),
                      style: CadenceType.display(34, color: CadenceColors.onPrimary)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.username, style: CadenceType.display(32)),
                    const SizedBox(height: 4),
                    Text('Listener since today', style: CadenceType.ui(13, weight: FontWeight.w400, color: CadenceColors.textSecondary)),
                  ]),
                ),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                _Stat(value: '${ratings.length}', label: 'Albums'),
                _Stat(value: ratings.isEmpty ? '–' : avg.toStringAsFixed(1), label: 'Avg rating'),
                _Stat(value: '${myReviews.length}', label: 'Reviews'),
              ]),
              const SizedBox(height: 8),
            ]),
          ),
        ),

        if (rated.isEmpty)
          SliverToBoxAdapter(child: _EmptyProfileState())
        else ...[
          if (taste.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 26)),
            const SliverToBoxAdapter(child: SectionHeader(title: 'Your sound', subtitle: 'Learned from your ratings')),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final (tag, _, _) in taste)
                    TagPill(label: tag, highlight: true, onTap: () => context.go('/search?q=${Uri.encodeComponent(tag)}')),
                ]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Diary', subtitle: 'Everything you rated, best first')),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverLayoutBuilder(builder: (context, c) {
              final cols = (c.crossAxisExtent / 110).floor().clamp(3, 8);
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 16, crossAxisSpacing: 10, childAspectRatio: 0.78),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final (album, stars) = rated[i];
                    return GestureDetector(
                      onTap: () => context.push('/album/${album.id}', extra: album),
                      child: LayoutBuilder(builder: (context, b) {
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          PosterCover(album: album, size: b.maxWidth, radius: 4),
                          const SizedBox(height: 6),
                          StarRating(rating: stars, size: (b.maxWidth / 7).clamp(10, 14)),
                        ]);
                      }),
                    );
                  },
                  childCount: rated.length,
                ),
              );
            }),
          ),
          if (myReviews.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            const SliverToBoxAdapter(child: SectionHeader(title: 'Recent reviews')),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverList.builder(
              itemCount: myReviews.take(5).length,
              itemBuilder: (context, i) => _ProfileReviewCard(review: myReviews[i], album: rec?.byId[myReviews[i].albumId]),
            ),
          ],
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: CadenceType.display(30)),
        Text(label.toUpperCase(), style: CadenceType.label(CadenceColors.textSecondary)),
      ]),
    );
  }
}

class _ProfileReviewCard extends StatelessWidget {
  final Review review;
  final Album? album;
  const _ProfileReviewCard({required this.review, this.album});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: album == null ? null : () => context.push('/album/${album!.id}', extra: album),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AlbumCover(url: album?.coverUrl, width: 54, height: 54, borderRadius: 4),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(album?.title ?? 'Album', style: CadenceType.ui(15, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              StarRating(rating: review.rating, size: 13),
              if (review.content != null && review.content!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(review.content!,
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: CadenceType.ui(13.5, weight: FontWeight.w400, color: CadenceColors.textSecondary).copyWith(height: 1.45)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: CadenceColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text('Your diary is empty', style: CadenceType.display(24)),
          const SizedBox(height: 8),
          Text('Rate a few albums and your sound shows up here.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/search'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(170, 46)),
            child: const Text('Find albums'),
          ),
        ]),
      ),
    );
  }
}

void _showSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: CadenceColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: CadenceColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.restart_alt_rounded, color: CadenceColors.textSecondary),
          title: Text('Clear my ratings', style: CadenceType.ui(15)),
          onTap: () {
            Navigator.pop(context);
            ref.read(ratingsProvider.notifier).clear();
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: CadenceColors.error),
          title: Text('Sign out', style: CadenceType.ui(15, color: CadenceColors.error)),
          onTap: () {
            Navigator.pop(context);
            ref.read(authProvider.notifier).signOut();
          },
        ),
      ]),
    ),
  );
}

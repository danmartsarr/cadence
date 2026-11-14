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
import '../../../shared/widgets/cover_color.dart';
import '../../../shared/widgets/poster.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(albumReviewsProvider(album.id));
    final tint = album.coverUrl == null ? null : ref.watch(coverColorProvider(album.coverUrl!)).valueOrNull;
    final header = tint ?? CadenceColors.surfaceElevated;
    final width = MediaQuery.sizeOf(context).width;
    final coverSize = (width * 0.62).clamp(200.0, 300.0);
    final totalMs = album.tracks.fold<int>(0, (s, t) => s + (t.durationMs ?? 0));

    return Scaffold(
      body: Stack(children: [
        // Header tinted with the cover's own colour, fading into the page
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          height: coverSize + 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [header, header.withAlpha(150), CadenceColors.background],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Center(
                      child: Container(
                        decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 18))]),
                        child: PosterCover(album: album, size: coverSize, radius: 6),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(album.title, style: CadenceType.display(width < 500 ? 34 : 42)),
                    const SizedBox(height: 8),
                    Text(album.artist, style: CadenceType.ui(16, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        'Album',
                        if (album.year != null) '${album.year}',
                        if (album.tracks.isNotEmpty) '${album.tracks.length} songs',
                        if (totalMs > 0) '${totalMs ~/ 60000} min',
                      ].join(' · '),
                      style: CadenceType.ui(13, weight: FontWeight.w400, color: CadenceColors.textSecondary),
                    ),
                    const SizedBox(height: 22),
                    _RatingBar(album: album),
                    const SizedBox(height: 28),
                    _WhyRecommended(albumId: album.id),
                    if (album.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in album.tags.keys.take(8))
                            TagPill(label: t, onTap: () => context.go('/search?q=${Uri.encodeComponent(t)}')),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (album.tracks.isNotEmpty) ...[
                      Text('Tracklist', style: CadenceType.ui(20, weight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ...album.tracks.map((t) => _TrackRow(track: t)),
                      const SizedBox(height: 32),
                    ],
                  ]),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _SimilarAlbums(albumId: album.id)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Reviews', style: CadenceType.ui(20, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    if (album.avgRating != null)
                      Row(children: [
                        StarRating(rating: album.avgRating!, size: 14),
                        const SizedBox(width: 8),
                        Text('${album.avgRating!.toStringAsFixed(1)} from ${album.ratingCount} MusicBrainz votes',
                            style: CadenceType.ui(12.5, weight: FontWeight.w400, color: CadenceColors.textSecondary)),
                      ]),
                    const SizedBox(height: 16),
                    if (reviews.isEmpty) _EmptyReviews(album: album) else ...reviews.map((r) => _ReviewCard(review: r)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Letterboxd-style action bar: rate inline, or open the full review sheet.
class _RatingBar extends ConsumerWidget {
  final Album album;
  const _RatingBar({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(ratingsProvider)[album.id];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mine == null ? 'RATE' : 'YOU RATED', style: CadenceType.label(CadenceColors.textSecondary)),
            const SizedBox(height: 6),
            StarRating(
              rating: mine ?? 0,
              size: 32,
              interactive: true,
              onChanged: (v) {
                ref.read(ratingsProvider.notifier).rate(album.id, v);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('Rated ${album.title} ${v.toStringAsFixed(1)}★'), duration: const Duration(seconds: 2)));
              },
            ),
          ]),
        ),
        if (mine != null)
          IconButton(
            tooltip: 'Remove rating',
            icon: const Icon(Icons.close_rounded, color: CadenceColors.textMuted, size: 20),
            onPressed: () => ref.read(ratingsProvider.notifier).remove(album.id),
          ),
        TextButton.icon(
          onPressed: () => _showReviewSheet(context, album),
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: const Text('Review'),
        ),
      ]),
    );
  }
}

/// The recommender's explanation, written as a sentence instead of a chart.
class _WhyRecommended extends ConsumerWidget {
  final String albumId;
  const _WhyRecommended({required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final why = ref.watch(explanationProvider(albumId));
    if (why == null) return const SizedBox.shrink();
    final loved = why.because.map((b) => b.album).toList();
    final names = loved.take(2).map((a) => a.title).toList();
    final tags = why.tags.take(4).map((e) => e.key).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WHY IT\'S ON YOUR RADAR', style: CadenceType.label(CadenceColors.primary)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (loved.isNotEmpty) ...[CoverFan(albums: loved, size: 58), const SizedBox(width: 16)],
          Expanded(
            child: Text.rich(
              TextSpan(style: CadenceType.display(21, color: CadenceColors.textSecondary), children: [
                if (names.isNotEmpty) ...[
                  const TextSpan(text: 'Because you loved '),
                  TextSpan(text: names.first, style: const TextStyle(color: CadenceColors.textPrimary)),
                  if (names.length > 1) ...[
                    const TextSpan(text: ' and '),
                    TextSpan(text: names[1], style: const TextStyle(color: CadenceColors.textPrimary)),
                  ],
                  const TextSpan(text: '.'),
                ] else
                  const TextSpan(text: 'It shares the sound of what you rate highly.'),
              ]),
            ),
          ),
        ]),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('They share', style: CadenceType.ui(12.5, weight: FontWeight.w500, color: CadenceColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final t in tags) TagPill(label: t, highlight: true)]),
        ],
        if (why.sameArtist) ...[
          const SizedBox(height: 14),
          Text('And it\'s by an artist you already rated well.',
              style: CadenceType.ui(12.5, weight: FontWeight.w500, color: CadenceColors.textSecondary)),
        ],
      ]),
    );
  }
}

class _SimilarAlbums extends ConsumerWidget {
  final String albumId;
  const _SimilarAlbums({required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similar = ref.watch(similarAlbumsProvider(albumId));
    if (similar.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Sounds like', subtitle: 'Albums with the closest sound'),
        const SizedBox(height: 16),
        SizedBox(
          height: 196,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, i) => PosterTile(album: similar[i].key),
          ),
        ),
      ]),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Track track;
  const _TrackRow({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        SizedBox(width: 32, child: Text('${track.position}', style: CadenceType.ui(14, weight: FontWeight.w400, color: CadenceColors.textSecondary))),
        Expanded(child: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.ui(15, weight: FontWeight.w500))),
        if (track.formattedDuration.isNotEmpty)
          Text(track.formattedDuration, style: CadenceType.ui(13, weight: FontWeight.w400, color: CadenceColors.textSecondary)),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: CadenceColors.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: CadenceColors.tileFor(review.userName),
          child: Text(review.userName.substring(0, 1).toUpperCase(), style: CadenceType.ui(12, weight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
              Text.rich(TextSpan(style: CadenceType.ui(13, weight: FontWeight.w400, color: CadenceColors.textSecondary), children: [
                const TextSpan(text: 'Review by '),
                TextSpan(text: review.userName, style: const TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w700)),
              ])),
              StarRating(rating: review.rating, size: 13),
            ]),
            if (review.content != null && review.content!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.content!, style: CadenceType.ui(14.5, weight: FontWeight.w400, color: CadenceColors.textPrimary).copyWith(height: 1.55)),
            ],
            if (review.favoriteTrack != null) ...[
              const SizedBox(height: 8),
              Text('♥ ${review.favoriteTrack!.title}', style: CadenceType.ui(12.5, weight: FontWeight.w600, color: CadenceColors.accent)),
            ],
            const SizedBox(height: 6),
            Text(_formatDate(review.createdAt), style: CadenceType.ui(11.5, weight: FontWeight.w400, color: CadenceColors.textMuted)),
          ]),
        ),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _EmptyReviews extends StatelessWidget {
  final Album album;
  const _EmptyReviews({required this.album});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: CadenceColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text('No reviews yet', style: CadenceType.display(22)),
        const SizedBox(height: 6),
        Text('Write the first one in your diary.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _showReviewSheet(context, album),
          style: OutlinedButton.styleFrom(minimumSize: const Size(170, 44)),
          child: const Text('Write a review'),
        ),
      ]),
    );
  }
}

void _showReviewSheet(BuildContext context, Album album) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewSheet(album: album),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final Album album;

  const _ReviewSheet({required this.album});

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late double _rating = ref.read(ratingsProvider)[widget.album.id] ?? 0;
  final _reviewCtrl = TextEditingController();
  Track? _favoriteTrack;
  Track? _leastFavoriteTrack;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final user = ref.read(authProvider).user;
    if (user == null || _rating == 0) return;

    final review = Review(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      albumId: widget.album.id,
      userId: user.id,
      userName: user.username,
      rating: _rating,
      content: _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
      favoriteTrack: _favoriteTrack,
      leastFavoriteTrack: _leastFavoriteTrack,
      createdAt: DateTime.now(),
    );

    ref.read(ratingsProvider.notifier).rate(widget.album.id, _rating);
    ref.read(reviewsProvider.notifier).addReview(review);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saved to your diary'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final hasTracks = widget.album.tracks.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: CadenceColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              AlbumCover(url: widget.album.coverUrl, width: 52, height: 52, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.album.title, style: const TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(widget.album.artist, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text('Your Rating', style: TextStyle(color: CadenceColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(
            children: [
              StarRating(
                rating: _rating,
                size: 36,
                interactive: true,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(width: 12),
              if (_rating > 0)
                Text(
                  _rating.toStringAsFixed(1),
                  style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 18, fontWeight: FontWeight.w700),
                ),
            ],
          ),

          const SizedBox(height: 20),

          const Text('Review (optional)', style: TextStyle(color: CadenceColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'What did you think of this album?',
              alignLabelWithHint: true,
            ),
          ),

          if (hasTracks) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TrackPicker(
                    label: 'Favorite Track',
                    icon: Icons.favorite,
                    iconColor: CadenceColors.success,
                    tracks: widget.album.tracks,
                    selected: _favoriteTrack,
                    onSelected: (t) => setState(() => _favoriteTrack = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrackPicker(
                    label: 'Skip Track',
                    icon: Icons.heart_broken,
                    iconColor: CadenceColors.error,
                    tracks: widget.album.tracks,
                    selected: _leastFavoriteTrack,
                    onSelected: (t) => setState(() => _leastFavoriteTrack = t),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _rating > 0 ? _submit : null,
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}

class _TrackPicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final List<Track> tracks;
  final Track? selected;
  final ValueChanged<Track?> onSelected;

  const _TrackPicker({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.tracks,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final track = await showDialog<Track?>(
          context: context,
          builder: (_) => _TrackPickerDialog(tracks: tracks, label: label),
        );
        if (track != null) onSelected(track);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CadenceColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected != null ? iconColor.withAlpha(128) : CadenceColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selected?.title ?? label,
                style: TextStyle(
                  color: selected != null ? CadenceColors.textPrimary : CadenceColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected != null ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackPickerDialog extends StatelessWidget {
  final List<Track> tracks;
  final String label;

  const _TrackPickerDialog({required this.tracks, required this.label});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CadenceColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tracks.length,
              itemBuilder: (_, i) {
                final t = tracks[i];
                return ListTile(
                  leading: Text('${t.position}', style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13)),
                  title: Text(t.title, style: const TextStyle(color: CadenceColors.textPrimary, fontSize: 14)),
                  trailing: t.formattedDuration.isNotEmpty
                      ? Text(t.formattedDuration, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 12))
                      : null,
                  onTap: () => Navigator.of(context).pop(t),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}



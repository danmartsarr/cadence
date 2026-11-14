import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/album.dart';
import '../../../shared/models/review.dart';
import '../../../shared/providers/albums_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/album_cover.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(albumReviewsProvider(album.id));
    final critics = reviews.where((r) => r.isCritic).toList();
    final users = reviews.where((r) => !r.isCritic).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: CadenceColors.background,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CadenceColors.surface.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: CadenceColors.textPrimary),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(color: CadenceColors.surface.withAlpha(200), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18, color: CadenceColors.textPrimary),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AlbumCover(url: album.coverUrl, borderRadius: 0, fit: BoxFit.cover),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.5, 1.0],
                        colors: [Color(0x33050A14), Colors.transparent, CadenceColors.background],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + artist
                  Text(album.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(album.artist, style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 15, fontWeight: FontWeight.w500)),
                      if (album.year != null) ...[
                        const Text('  ·  ', style: TextStyle(color: CadenceColors.textSecondary)),
                        Text(album.year.toString(), style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      if (album.avgRating != null) ...[
                        _StatChip(
                          icon: Icons.star,
                          label: album.avgRating!.toStringAsFixed(2),
                          sub: 'avg rating',
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (album.ratingCount > 0)
                        _StatChip(
                          icon: Icons.how_to_vote_outlined,
                          label: _formatCount(album.ratingCount),
                          sub: 'votes',
                        ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.rate_review_outlined,
                        label: reviews.length.toString(),
                        sub: 'reviews',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Rate / Review CTA
                  _RateButton(album: album),

                  const SizedBox(height: 24),

                  // Why this was recommended (content-based explanation)
                  _WhyRecommended(albumId: album.id),

                  if (album.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: album.tags.keys.take(8).map((t) => _TagPill(label: t)).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Nearest neighbours in tag space
                  _SimilarAlbums(albumId: album.id),

                  const SizedBox(height: 8),

                  // Tracklist
                  if (album.tracks.isNotEmpty) ...[
                    Text('Tracklist', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...album.tracks.asMap().entries.map((e) => _TrackRow(track: e.value)),
                    const SizedBox(height: 28),
                  ],

                  // Critic Reviews
                  if (critics.isNotEmpty) ...[
                    Row(
                      children: [
                        Text('Critic Reviews', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: CadenceColors.primary.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                          child: Text('${critics.length}', style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...critics.map((r) => _ReviewCard(review: r)),
                    const SizedBox(height: 28),
                  ],

                  // User Reviews
                  Row(
                    children: [
                      Text('Community Reviews', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: CadenceColors.primary.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                        child: Text('${users.length}', style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (users.isEmpty)
                    _EmptyReviews(album: album)
                  else
                    ...users.map((r) => _ReviewCard(review: r)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _StatChip({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: CadenceColors.primaryLight, size: 14),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          Text(sub, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Track track;

  const _TrackRow({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CadenceColors.border, width: 0.5))),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(track.position.toString(), style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(track.title, style: const TextStyle(color: CadenceColors.textPrimary, fontSize: 14))),
          if (track.formattedDuration.isNotEmpty)
            Text(track.formattedDuration, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: review.isCritic ? CadenceColors.primary : CadenceColors.surfaceElevated,
                child: Text(
                  review.userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review.userName, style: const TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        if (review.isCritic) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: CadenceColors.primary.withAlpha(50), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Critic', style: TextStyle(color: CadenceColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              StarRating(rating: review.rating, size: 14),
            ],
          ),
          if (review.content != null && review.content!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.content!, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13, height: 1.5)),
          ],
          if (review.favoriteTrack != null || review.leastFavoriteTrack != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (review.favoriteTrack != null)
              _TrackBadge(icon: Icons.favorite, label: 'Fav track', track: review.favoriteTrack!.title, color: CadenceColors.success),
            if (review.leastFavoriteTrack != null) ...[
              const SizedBox(height: 6),
              _TrackBadge(icon: Icons.heart_broken, label: 'Skip', track: review.leastFavoriteTrack!.title, color: CadenceColors.error),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _TrackBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String track;
  final Color color;

  const _TrackBadge({required this.icon, required this.label, required this.track, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(child: Text(track, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  final Album album;

  const _EmptyReviews({required this.album});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined, color: CadenceColors.textSecondary, size: 32),
          const SizedBox(height: 10),
          Text('No reviews yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Be the first to review this album', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _showReviewSheet(context, album),
            style: OutlinedButton.styleFrom(minimumSize: const Size(160, 42)),
            child: const Text('Write a Review'),
          ),
        ],
      ),
    );
  }
}

class _RateButton extends ConsumerWidget {
  final Album album;

  const _RateButton({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showReviewSheet(context, album),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: CadenceColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.star_border, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Rate or Review this Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
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
  double _rating = 0;
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

    ref.read(reviewsProvider.notifier).addReview(review);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Review submitted!'),
        backgroundColor: CadenceColors.success,
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


class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Text(label, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 12)),
    );
  }
}

/// Shows which of the user's ratings and which tags pushed this album up.
class _WhyRecommended extends ConsumerWidget {
  final String albumId;
  const _WhyRecommended({required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final why = ref.watch(explanationProvider(albumId));
    if (why == null) return const SizedBox.shrink();
    final maxTag = why.tags.isEmpty ? 1.0 : why.tags.first.value;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CadenceColors.primary.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.insights, color: CadenceColors.primaryLight, size: 18),
            const SizedBox(width: 8),
            Text('Why you might like it', style: Theme.of(context).textTheme.titleMedium),
          ]),
          if (why.because.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Close to albums you rated', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ...why.because.map((inf) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    AlbumCover(url: inf.album.coverUrl, width: 36, height: 36, borderRadius: 6),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${inf.album.title} · ${inf.album.artist}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: CadenceColors.textPrimary, fontSize: 13)),
                    ),
                    Text('${inf.rating.toStringAsFixed(1)}★',
                        style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                )),
          ],
          if (why.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Shared traits (contribution to the score)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ...why.tags.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(width: 120, child: Text(t.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: t.value / maxTag,
                          minHeight: 6,
                          backgroundColor: CadenceColors.border,
                          valueColor: const AlwaysStoppedAnimation(CadenceColors.primaryLight),
                        ),
                      ),
                    ),
                  ]),
                )),
          ],
          if (why.sameArtist) ...[
            const SizedBox(height: 6),
            const Text('Also: an artist you already rated well', style: TextStyle(color: CadenceColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sounds like', style: Theme.of(context).textTheme.titleLarge),
        Text('Nearest albums by cosine similarity of tag profiles', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 176,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            itemBuilder: (_, i) {
              final a = similar[i].key;
              return GestureDetector(
                onTap: () => context.push('/album/${a.id}', extra: a),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AlbumCover(url: a.coverUrl, width: 120, height: 120, borderRadius: 10),
                    const SizedBox(height: 6),
                    Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CadenceColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${(similar[i].value * 100).round()}% match', style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 11)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/review.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/albums_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final allReviews = ref.watch(reviewsProvider);
    final myReviews = allReviews.where((r) => r.userId == user.id).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: CadenceColors.background,
            pinned: true,
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: CadenceColors.textSecondary),
                onPressed: () => _showSettingsSheet(context, ref),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Avatar + info
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: CadenceColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.username, style: Theme.of(context).textTheme.headlineSmall),
                            Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    children: [
                      _StatBox(label: 'Reviews', value: myReviews.length.toString()),
                      const SizedBox(width: 12),
                      _StatBox(label: 'Friends', value: user.friendIds.length.toString()),
                      const SizedBox(width: 12),
                      _StatBox(label: 'Lists', value: '0'),
                    ],
                  ),

                  const SizedBox(height: 28),

                  if (myReviews.isEmpty) ...[
                    _EmptyProfileState(),
                  ] else ...[
                    Text('Recent Reviews', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    ...myReviews.take(5).map((r) => _ProfileReviewCard(review: r)),
                  ],

                  const SizedBox(height: 32),

                  // Taste profile mock
                  Text('Your Taste Profile', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  _TasteProfile(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: CadenceColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CadenceColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: CadenceColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ProfileReviewCard extends StatelessWidget {
  final Review review;

  const _ProfileReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.albumId,
                  style: const TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: CadenceColors.starActive, size: 14),
                  const SizedBox(width: 3),
                  Text(review.rating.toStringAsFixed(1), style: const TextStyle(color: CadenceColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ],
          ),
          if (review.content != null && review.content!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.content!, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _TasteProfile extends StatelessWidget {
  final _genres = [
    ('Hip-Hop', 0.85),
    ('Electronic', 0.62),
    ('Indie', 0.54),
    ('R&B', 0.41),
    ('Rock', 0.30),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Column(
        children: _genres.map((g) {
          final (name, value) = g;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(name, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 12))),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: CadenceColors.border,
                      valueColor: const AlwaysStoppedAnimation(CadenceColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(value * 100).toInt()}%', style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: CadenceColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CadenceColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.album_outlined, color: CadenceColors.textSecondary, size: 48),
          const SizedBox(height: 16),
          Text('No reviews yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Start rating albums to build your music profile',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.go('/search'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(140, 42)),
            child: const Text('Discover Albums'),
          ),
        ],
      ),
    );
  }
}

void _showSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: CadenceColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: CadenceColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person_outline, color: CadenceColors.textSecondary),
            title: const Text('Edit Profile', style: TextStyle(color: CadenceColors.textPrimary)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: CadenceColors.textSecondary),
            title: const Text('Notifications', style: TextStyle(color: CadenceColors.textPrimary)),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: CadenceColors.border),
          ListTile(
            leading: const Icon(Icons.logout, color: CadenceColors.error),
            title: const Text('Sign Out', style: TextStyle(color: CadenceColors.error)),
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
    ),
  );
}

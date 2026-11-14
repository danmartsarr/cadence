import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/album.dart';
import '../../../shared/providers/albums_provider.dart';
import '../../../shared/widgets/album_cover.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(albumSearchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(albumSearchProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text('Find albums, artists, and more', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ctrl,
                    onChanged: _onChanged,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search albums or artists...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: CadenceColors.textSecondary),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: CadenceColors.textSecondary),
                              onPressed: () {
                                _ctrl.clear();
                                ref.read(albumSearchProvider.notifier).clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator(color: CadenceColors.primary)),
                error: (err, stack) => Center(child: Text('Something went wrong', style: Theme.of(context).textTheme.bodyMedium)),
                data: (albums) {
                  if (_ctrl.text.isEmpty) return _GenreGrid();
                  if (albums.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, color: CadenceColors.textSecondary, size: 40),
                          const SizedBox(height: 12),
                          Text('No results for "${_ctrl.text}"', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }
                  return _SearchResults(albums: albums);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<Album> albums;

  const _SearchResults({required this.albums});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: albums.length,
      itemBuilder: (_, i) {
        final album = albums[i];
        return GestureDetector(
          onTap: () => context.push('/album/${album.id}', extra: album),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CadenceColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CadenceColors.border),
            ),
            child: Row(
              children: [
                AlbumCover(url: album.coverUrl, width: 56, height: 56, borderRadius: 8),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.title, style: const TextStyle(color: CadenceColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(album.artist, style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 13)),
                      if (album.year != null) ...[
                        const SizedBox(height: 2),
                        Text(album.year.toString(), style: const TextStyle(color: CadenceColors.textSecondary, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                if (album.avgRating != null)
                  Column(
                    children: [
                      const Icon(Icons.star, color: CadenceColors.starActive, size: 14),
                      Text(album.avgRating!.toStringAsFixed(1), style: const TextStyle(color: CadenceColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: CadenceColors.textSecondary, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GenreGrid extends StatelessWidget {
  final _genres = [
    ('Hip-Hop', Icons.mic_external_on_outlined, CadenceColors.primary),
    ('Rock', Icons.electric_bolt_outlined, Color(0xFF8E44AD)),
    ('Electronic', Icons.waves_outlined, Color(0xFF16A085)),
    ('Jazz', Icons.music_note_outlined, Color(0xFFD68910)),
    ('R&B', Icons.favorite_border, Color(0xFFCB4335)),
    ('Pop', Icons.star_border, Color(0xFF2E86C1)),
    ('Classical', Icons.piano_outlined, Color(0xFF1F618D)),
    ('Indie', Icons.queue_music_outlined, Color(0xFF138D75)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Browse by Genre', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: _genres.length,
              itemBuilder: (_, i) {
                final (name, icon, color) = _genres[i];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withAlpha(200), color.withAlpha(100)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(icon, color: Colors.white.withAlpha(200), size: 20),
                      const SizedBox(width: 10),
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

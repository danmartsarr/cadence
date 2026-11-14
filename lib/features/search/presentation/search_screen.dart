import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/album.dart';
import '../../../shared/providers/albums_provider.dart';
import '../../../shared/widgets/album_cover.dart';
import '../../../shared/widgets/poster.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _ctrl = TextEditingController(text: widget.initialQuery ?? '');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (q != null && q.isNotEmpty) {
      Future.microtask(() => ref.read(albumSearchProvider.notifier).search(q));
    }
  }

  @override
  void didUpdateWidget(SearchScreen old) {
    super.didUpdateWidget(old);
    final q = widget.initialQuery;
    if (q != null && q != old.initialQuery) _search(q);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String q) {
    _ctrl.text = q;
    ref.read(albumSearchProvider.notifier).search(q);
    setState(() {});
  }

  void _onChanged(String query) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => ref.read(albumSearchProvider.notifier).search(query));
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(albumSearchProvider);
    final query = _ctrl.text.trim();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Search', style: CadenceType.display(38)),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  onChanged: _onChanged,
                  style: CadenceType.ui(15, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Albums, artists, genres, moods',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22, color: CadenceColors.textSecondary),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: CadenceColors.textSecondary),
                            onPressed: () {
                              _ctrl.clear();
                              ref.read(albumSearchProvider.notifier).clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ]),
            ),
          ),
          if (query.isEmpty) ..._browse() else ..._results(results, query),
        ]),
      ),
    );
  }

  List<Widget> _browse() {
    final tags = ref.watch(topTagsProvider).valueOrNull ?? const [];
    final rec = ref.watch(recommenderProvider).valueOrNull;
    Album? coverFor(String tag) {
      if (rec == null) return null;
      final withTag = rec.albums.where((a) => a.tags.containsKey(tag)).toList()
        ..sort((a, b) => (b.tags[tag]! * (b.avgRating ?? 3)).compareTo(a.tags[tag]! * (a.avgRating ?? 3)));
      return withTag.isEmpty ? null : withTag.first;
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Text('Browse by sound', style: CadenceType.ui(18, weight: FontWeight.w800)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        sliver: SliverLayoutBuilder(builder: (context, c) {
          final cols = c.crossAxisExtent > 900 ? 4 : c.crossAxisExtent > 560 ? 3 : 2;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.75),
            delegate: SliverChildBuilderDelegate(
              (context, i) => LayoutBuilder(
                builder: (context, b) => GenreTile(label: tags[i], cover: coverFor(tags[i]), width: b.maxWidth, height: b.maxHeight, onTap: () => _search(tags[i])),
              ),
              childCount: tags.length,
            ),
          );
        }),
      ),
    ];
  }

  List<Widget> _results(AsyncValue<List<Album>> results, String query) {
    return results.when(
      loading: () => [const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: CadenceColors.primary))))],
      error: (e, _) => [SliverToBoxAdapter(child: Center(child: Text('Search failed', style: Theme.of(context).textTheme.bodySmall)))],
      data: (albums) => albums.isEmpty
          ? [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(children: [
                    Text('Nothing for “$query”', style: CadenceType.display(24)),
                    const SizedBox(height: 6),
                    Text('Try an artist, a genre or a mood.', style: Theme.of(context).textTheme.bodyMedium),
                  ]),
                ),
              ),
            ]
          : [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('${albums.length} albums', style: CadenceType.label(CadenceColors.textSecondary)),
                ),
              ),
              SliverList.builder(itemCount: albums.length, itemBuilder: (context, i) => _ResultRow(album: albums[i])),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Album album;
  const _ResultRow({required this.album});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/album/${album.id}', extra: album),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          PosterCover(album: album, size: 56, radius: 4),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.ui(15, weight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('Album · ${album.artist}${album.year != null ? ' · ${album.year}' : ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.ui(13, weight: FontWeight.w400, color: CadenceColors.textSecondary)),
            ]),
          ),
          if (album.avgRating != null) StarRating(rating: album.avgRating!, size: 12),
        ]),
      ),
    );
  }
}

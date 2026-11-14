import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/album.dart';
import '../../../shared/providers/albums_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/album_cover.dart';
import '../../../shared/widgets/poster.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat(reverse: true);

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(catalogProvider).valueOrNull ?? const <Album>[];
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > 760;

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        if (albums.isNotEmpty) _Mosaic(albums: albums, drift: _drift),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE60E1013), Color(0x8C0E1013), Color(0xB30E1013), Color(0xF20E1013), CadenceColors.background],
              stops: [0, 0.14, 0.38, 0.62, 1],
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const CadenceMark(size: 30),
                    const SizedBox(width: 10),
                    Text('cadence', style: CadenceType.display(26)),
                  ]),
                  const Spacer(),
                  Text('Every album\nhas a story.', style: CadenceType.display(wide ? 68 : 52)),
                  const SizedBox(height: 16),
                  Text(
                    'Keep a diary of the records you love. Rate them, and cadence tells you what to play next, and why.',
                    style: CadenceType.ui(16, weight: FontWeight.w400, color: CadenceColors.textSecondary).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => ref.read(authProvider.notifier).signIn('guest@cadence.demo', 'demo'),
                    child: const Text('Try the demo'),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => context.push('/sign-up'), child: const Text('Create account'))),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton(onPressed: () => context.push('/sign-in'), child: const Text('Sign in'))),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Slowly drifting wall of covers from the catalog.
class _Mosaic extends StatelessWidget {
  final List<Album> albums;
  final Animation<double> drift;
  const _Mosaic({required this.albums, required this.drift});

  @override
  Widget build(BuildContext context) {
    final withCovers = albums.where((a) => a.coverUrl != null).toList()..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    final pool = withCovers.take(48).toList();
    return LayoutBuilder(builder: (context, c) {
      const tile = 132.0, gap = 10.0;
      final rows = (c.maxHeight / (tile + gap)).ceil() + 1;
      final perRow = (c.maxWidth / (tile + gap)).ceil() + 3;
      return ClipRect(
        child: AnimatedBuilder(
          animation: drift,
          builder: (context, _) => OverflowBox(
            alignment: Alignment.topLeft,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.rotate(
              angle: -0.06,
              child: Column(children: [
                for (var r = 0; r < rows; r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: gap),
                    child: Transform.translate(
                      offset: Offset(-(tile + gap) * 2 + ((r.isEven ? 1 : -1) * drift.value * (tile + gap) * 2), 0),
                      child: Row(children: [
                        for (var i = 0; i < perRow; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: gap),
                            child: AlbumCover(url: pool[(r * 7 + i) % pool.length].coverUrl, width: tile, height: tile, borderRadius: 4),
                          ),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../models/album.dart';
import 'album_cover.dart';

/// Cover framed like a film poster: square, thin light border, soft shadow.
class PosterCover extends StatelessWidget {
  final Album album;
  final double size;
  final double radius;
  const PosterCover({super.key, required this.album, required this.size, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: AlbumCover(url: album.coverUrl, width: size, height: size, borderRadius: radius),
    );
  }
}

/// Poster + title + a caption line (artist, a reason, or stars).
class PosterTile extends StatelessWidget {
  final Album album;
  final double size;
  final String? caption;
  final double? stars;
  final Widget? badge;
  const PosterTile({super.key, required this.album, this.size = 140, this.caption, this.stars, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/album/${album.id}', extra: album),
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              PosterCover(album: album, size: size),
              if (badge != null) Positioned(left: 8, top: 8, child: badge!),
            ]),
            const SizedBox(height: 10),
            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.ui(13.5, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            if (stars != null)
              StarRating(rating: stars!, size: 13)
            else
              Text(caption ?? album.artist,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: CadenceType.ui(12, weight: FontWeight.w400, color: CadenceColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class MatchPill extends StatelessWidget {
  final double score;
  const MatchPill({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score.clamp(0, 1) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: CadenceColors.primary, borderRadius: BorderRadius.circular(999)),
      child: Text('$pct% match', style: CadenceType.ui(11, weight: FontWeight.w800, color: CadenceColors.onPrimary)),
    );
  }
}

class TagPill extends StatelessWidget {
  final String label;
  final bool highlight;
  final VoidCallback? onTap;
  const TagPill({super.key, required this.label, this.highlight = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: highlight ? CadenceColors.primary.withAlpha(36) : CadenceColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: highlight ? CadenceColors.primary.withAlpha(140) : Colors.transparent),
        ),
        child: Text(label,
            style: CadenceType.ui(12.5, weight: FontWeight.w600, color: highlight ? CadenceColors.primaryLight : CadenceColors.textPrimary)),
      ),
    );
  }
}

/// Colour block with a tilted cover in the corner, like a genre tile in a streaming app.
class GenreTile extends StatelessWidget {
  final String label;
  final Album? cover;
  final double width;
  final double height;
  final VoidCallback? onTap;
  const GenreTile({super.key, required this.label, this.cover, this.width = 170, this.height = 96, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = CadenceColors.tileFor(label);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
        child: Stack(children: [
          if (cover != null)
            Positioned(
              right: -14,
              bottom: -6,
              child: Transform.rotate(angle: 0.42, child: PosterCover(album: cover!, size: height * 0.72, radius: 4)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 60, 12),
            child: Text(_title(label), style: CadenceType.ui(16, weight: FontWeight.w800, spacing: -0.3)),
          ),
        ]),
      ),
    );
  }

  static const _upper = {'mpb', 'r&b', 'edm', 'uk', 'us', 'idm', 'dnb', 'lo-fi'};

  static String _title(String s) => s
      .split(' ')
      .map((w) => _upper.contains(w.toLowerCase()) ? w.toUpperCase() : (w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)))
      .join(' ');
}

/// Up to three covers fanned out, like records pulled from a shelf.
class CoverFan extends StatelessWidget {
  final List<Album> albums;
  final double size;
  const CoverFan({super.key, required this.albums, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final list = albums.take(3).toList();
    final angles = [-0.16, 0.0, 0.16];
    final offsets = [0.0, size * 0.42, size * 0.84];
    return SizedBox(
      width: size + offsets[list.length - 1] + 8,
      height: size + 14,
      child: Stack(clipBehavior: Clip.none, children: [
        for (var i = list.length - 1; i >= 0; i--)
          Positioned(
            left: offsets[i],
            top: 6,
            child: Transform.rotate(angle: list.length == 1 ? 0 : angles[i], child: PosterCover(album: list[i], size: size, radius: 4)),
          ),
      ]),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  const SectionHeader({super.key, required this.title, this.subtitle, this.eyebrow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(), style: CadenceType.label(CadenceColors.primary)),
          const SizedBox(height: 6),
        ],
        Text(title, style: CadenceType.ui(22, weight: FontWeight.w800, spacing: -0.5)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: CadenceType.ui(13, weight: FontWeight.w400, color: CadenceColors.textSecondary)),
        ],
      ]),
    );
  }
}

/// Small brand mark: a record with a green label.
class CadenceMark extends StatelessWidget {
  final double size;
  const CadenceMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF050607)),
      foregroundDecoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x33FFFFFF))),
      child: Center(
        child: Container(
          width: size * 0.42,
          height: size * 0.42,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: CadenceColors.primary),
          child: Center(child: Container(width: size * 0.1, height: size * 0.1, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF050607)))),
        ),
      ),
    );
  }
}

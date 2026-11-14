import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/colors.dart';

class AlbumCover extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  const AlbumCover({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: fit,
              placeholder: (context, url) => _shimmer(),
              errorWidget: (context, url, error) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: CadenceColors.surface,
      highlightColor: CadenceColors.surfaceElevated,
      child: Container(
        width: width,
        height: height,
        color: CadenceColors.surface,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: CadenceColors.surface,
      child: const Icon(Icons.album, color: CadenceColors.textSecondary, size: 40),
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final double maxRating;
  final double size;
  final bool interactive;
  final ValueChanged<double>? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.interactive = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stars = maxRating.toInt();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(stars, (i) {
        final value = i + 1.0;
        final filled = rating >= value;
        final half = !filled && rating >= value - 0.5;

        final icon = filled
            ? Icons.star
            : half
                ? Icons.star_half
                : Icons.star_border;

        if (!interactive) {
          return Icon(icon, color: CadenceColors.starActive, size: size);
        }

        return GestureDetector(
          onTap: () => onChanged?.call(value),
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final local = box.globalToLocal(d.globalPosition);
            final w = box.size.width;
            final newRating = ((local.dx / w) * stars).clamp(0.5, stars.toDouble());
            onChanged?.call((newRating * 2).round() / 2);
          },
          child: Icon(icon, color: CadenceColors.starActive, size: size),
        );
      }),
    );
  }
}

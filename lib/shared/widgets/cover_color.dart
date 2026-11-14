import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dominant colour of a cover, toned down for a dark header gradient.
/// Pixels are bucketed by hue and weighted by saturation, so a small vivid
/// area beats a large grey background (the way streaming apps tint headers).
final coverColorProvider = FutureProvider.family<Color?, String>((ref, url) async {
  try {
    final completer = Completer<ui.Image>();
    final stream = CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (!completer.isCompleted) completer.complete(info.image.clone());
      stream.removeListener(listener);
    }, onError: (e, _) {
      if (!completer.isCompleted) completer.completeError(e);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    final image = await completer.future.timeout(const Duration(seconds: 12));
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final w = image.width, h = image.height;
    image.dispose();
    if (data == null) return null;

    final sums = List.generate(12, (_) => [0.0, 0.0, 0.0, 0.0]);
    final step = ((w * h) / 4000).ceil().clamp(1, 1 << 20);
    for (var i = 0; i < w * h; i += step) {
      final o = i * 4;
      final c = HSVColor.fromColor(Color.fromARGB(255, data.getUint8(o), data.getUint8(o + 1), data.getUint8(o + 2)));
      final weight = c.saturation * c.value + 0.02;
      final b = sums[(c.hue / 30).floor() % 12];
      b[0] += data.getUint8(o) * weight;
      b[1] += data.getUint8(o + 1) * weight;
      b[2] += data.getUint8(o + 2) * weight;
      b[3] += weight;
    }
    sums.sort((a, b) => b[3].compareTo(a[3]));
    final best = sums.first;
    if (best[3] == 0) return null;
    final raw = Color.fromARGB(255, (best[0] / best[3]).round(), (best[1] / best[3]).round(), (best[2] / best[3]).round());
    final hsl = HSLColor.fromColor(raw);
    return hsl.withLightness(hsl.lightness.clamp(0.26, 0.40)).withSaturation(hsl.saturation.clamp(0.0, 0.62)).toColor();
  } catch (_) {
    return null;
  }
});

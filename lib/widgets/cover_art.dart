import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';

class CoverArt extends StatelessWidget {
  const CoverArt({required this.song, this.size = 56, super.key});

  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6);

    if (song.coverUrl == null) {
      if (song.embeddedCoverBytes != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            song.embeddedCoverBytes!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _FallbackCover(size: size),
          ),
        );
      }
      return _FallbackCover(size: size);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: song.coverUrl.toString(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _FallbackCover(size: size),
        errorWidget: (_, _, _) => _FallbackCover(size: size),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.album, color: AppColors.textSecondary),
    );
  }
}

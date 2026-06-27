import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/cover_art_service.dart';
import '../theme/app_theme.dart';

class CoverArt extends StatelessWidget {
  const CoverArt({
    required this.song,
    required this.coverArtService,
    this.size = 56,
    super.key,
  });

  final Song song;
  final CoverArtService coverArtService;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6);

    return ListenableBuilder(
      listenable: coverArtService,
      builder: (context, _) {
        final embeddedBytes =
            coverArtService.coverFor(song.id) ?? song.embeddedCoverBytes;

        if (song.coverUrl == null) {
          if (embeddedBytes != null) {
            return ClipRRect(
              borderRadius: borderRadius,
              child: Image.memory(
                embeddedBytes,
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
      },
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

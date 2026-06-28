import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/cover_art_service.dart';
import '../theme/app_theme.dart';
import 'cover_art.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    required this.song,
    required this.coverArtService,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
    super.key,
  });

  final Song song;
  final CoverArtService coverArtService;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.card : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CoverArt(song: song, coverArtService: coverArtService, size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SongStatusIcon(isActive: isActive, isPlaying: isPlaying),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongStatusIcon extends StatelessWidget {
  const _SongStatusIcon({required this.isActive, required this.isPlaying});

  final bool isActive;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final icon = isActive
        ? (isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded)
        : Icons.play_arrow_rounded;
    final foreground = isActive ? Colors.black : AppColors.textPrimary;
    final background = isActive ? AppColors.accent : AppColors.surfaceAlt;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 22),
    );
  }
}

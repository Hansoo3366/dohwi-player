import 'package:flutter/material.dart';

import '../controllers/player_controller.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';
import 'cover_art.dart';
import 'playback_progress.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({required this.controller, super.key});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final song = controller.currentSong;

        return Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PlayerScreen(controller: controller),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.surfaceAlt, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlaybackProgress(controller: controller),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      final coverSize = compact ? 42.0 : 48.0;
                      final playSize = compact ? 48.0 : 54.0;

                      return Row(
                        children: [
                          if (song != null)
                            CoverArt(
                              song: song,
                              coverArtService: controller.coverArtService,
                              size: coverSize,
                            )
                          else
                            Container(
                              width: coverSize,
                              height: coverSize,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.album),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song?.title ?? '노래를 골라주세요',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  song?.artist.isNotEmpty == true
                                      ? song!.artist
                                      : '도휘 플레이어',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!compact)
                            IconButton(
                              tooltip: '이전곡',
                              onPressed: controller.hasSongs
                                  ? controller.previous
                                  : null,
                              icon: const Icon(Icons.skip_previous_rounded),
                            ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: playSize,
                            height: playSize,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.zero,
                                shape: const CircleBorder(),
                              ),
                              onPressed: controller.hasSongs
                                  ? controller.togglePlayPause
                                  : null,
                              child: Icon(
                                controller.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: compact ? 28 : 30,
                              ),
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: '다음곡',
                              onPressed: controller.hasSongs
                                  ? controller.next
                                  : null,
                              icon: const Icon(Icons.skip_next_rounded),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

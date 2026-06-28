import 'package:flutter/material.dart';

import '../controllers/player_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/cover_art.dart';
import '../widgets/playback_options.dart';
import '../widgets/playback_progress.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({required this.controller, super.key});

  final PlayerController controller;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const double _dismissDistance = 90;
  static const double _dismissVelocity = 650;

  double _verticalDragDistance = 0;

  void _handleVerticalDragStart(DragStartDetails details) {
    _verticalDragDistance = 0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    if (delta <= 0) {
      return;
    }

    setState(() {
      _verticalDragDistance += delta;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _verticalDragDistance >= _dismissDistance ||
        velocity >= _dismissVelocity;

    if (shouldDismiss) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _verticalDragDistance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final dragOffset = _verticalDragDistance.clamp(0, 140).toDouble();

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: _handleVerticalDragStart,
          onVerticalDragUpdate: _handleVerticalDragUpdate,
          onVerticalDragEnd: _handleVerticalDragEnd,
          child: AnimatedSlide(
            duration: dragOffset == 0
                ? const Duration(milliseconds: 180)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            offset: Offset(0, dragOffset / MediaQuery.sizeOf(context).height),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final song = controller.currentSong;
                final coverSize = MediaQuery.sizeOf(
                  context,
                ).width.clamp(220, 360);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: '닫기',
                            onPressed: () => Navigator.of(context).maybePop(),
                            iconSize: 36,
                            constraints: const BoxConstraints.tightFor(
                              width: 56,
                              height: 56,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          const Expanded(
                            child: Text(
                              '재생 중',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 56),
                        ],
                      ),
                      const Spacer(),
                      if (song != null)
                        CoverArt(
                          song: song,
                          coverArtService: controller.coverArtService,
                          size: coverSize.toDouble(),
                        )
                      else
                        Container(
                          width: coverSize.toDouble(),
                          height: coverSize.toDouble(),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.album, size: 72),
                        ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          song?.title ?? '노래를 골라주세요',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          song?.artist.isNotEmpty == true
                              ? song!.artist
                              : '도휘 플레이어',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PlaybackProgress(controller: controller, showTimes: true),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: '이전곡',
                            onPressed: controller.hasSongs
                                ? controller.previous
                                : null,
                            iconSize: 44,
                            icon: const Icon(Icons.skip_previous_rounded),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 76,
                            height: 76,
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
                                size: 44,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            tooltip: '다음곡',
                            onPressed: controller.hasSongs
                                ? controller.next
                                : null,
                            iconSize: 44,
                            icon: const Icon(Icons.skip_next_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      PlaybackOptions(controller: controller),
                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/player_controller.dart';
import '../models/song.dart';
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
    setState(() {
      _verticalDragDistance = (_verticalDragDistance + delta)
          .clamp(0, 140)
          .toDouble();
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
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 640;
                    final isShort = constraints.maxHeight < 720;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 28 : 20,
                        12,
                        isWide ? 28 : 20,
                        isWide ? 20 : 24,
                      ),
                      child: Column(
                        children: [
                          _Header(
                            onClose: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: isWide || isShort
                                ? _WidePlayerLayout(
                                    controller: controller,
                                    maxWidth: constraints.maxWidth,
                                    maxHeight: constraints.maxHeight,
                                  )
                                : _PortraitPlayerLayout(
                                    controller: controller,
                                    maxWidth: constraints.maxWidth,
                                    maxHeight: constraints.maxHeight,
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '닫기',
          onPressed: onClose,
          iconSize: 36,
          constraints: const BoxConstraints.tightFor(width: 56, height: 56),
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
    );
  }
}

class _PortraitPlayerLayout extends StatelessWidget {
  const _PortraitPlayerLayout({
    required this.controller,
    required this.maxWidth,
    required this.maxHeight,
  });

  final PlayerController controller;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final song = controller.currentSong;
    final coverSize = math.min(maxWidth - 40, maxHeight * 0.42).clamp(220, 360);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: math.max(0, maxHeight - 76)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Cover(
              controller: controller,
              song: song,
              size: coverSize.toDouble(),
            ),
            const SizedBox(height: 32),
            _SongInfo(song: song),
            const SizedBox(height: 24),
            PlaybackProgress(controller: controller, showTimes: true),
            const SizedBox(height: 24),
            _TransportControls(controller: controller),
            const SizedBox(height: 22),
            PlaybackOptions(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _WidePlayerLayout extends StatelessWidget {
  const _WidePlayerLayout({
    required this.controller,
    required this.maxWidth,
    required this.maxHeight,
  });

  final PlayerController controller;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final song = controller.currentSong;
    final coverSize = math
        .min(math.min(maxWidth * 0.36, maxHeight * 0.68), 360)
        .clamp(180, 360)
        .toDouble();

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: _Cover(controller: controller, song: song, size: coverSize),
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SongInfo(song: song),
                    const SizedBox(height: 22),
                    PlaybackProgress(controller: controller, showTimes: true),
                    const SizedBox(height: 22),
                    _TransportControls(controller: controller),
                    const SizedBox(height: 18),
                    PlaybackOptions(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.controller,
    required this.song,
    required this.size,
  });

  final PlayerController controller;
  final Song? song;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (song != null) {
      return CoverArt(
        song: song!,
        coverArtService: controller.coverArtService,
        size: size,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.album, size: 72),
    );
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({required this.song});

  final Song? song;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song?.title ?? '노래를 골라주세요',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          song?.artist.isNotEmpty == true ? song!.artist : '도휘 플레이어',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: '이전곡',
          onPressed: controller.hasSongs ? controller.previous : null,
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
            onPressed: controller.hasSongs ? controller.togglePlayPause : null,
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
          onPressed: controller.hasSongs ? controller.next : null,
          iconSize: 44,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

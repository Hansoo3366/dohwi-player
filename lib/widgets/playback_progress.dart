import 'package:flutter/material.dart';

import '../controllers/player_controller.dart';
import '../theme/app_theme.dart';

class PlaybackProgress extends StatelessWidget {
  const PlaybackProgress({
    required this.controller,
    this.showTimes = false,
    super.key,
  });

  final PlayerController controller;
  final bool showTimes;

  @override
  Widget build(BuildContext context) {
    final duration = controller.audioHandler.player.duration ?? Duration.zero;
    final position = controller.audioHandler.player.position;
    final max = duration.inMilliseconds.toDouble().clamp(1, double.infinity);
    final value = position.inMilliseconds.toDouble().clamp(0, max);

    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.card,
        thumbColor: AppColors.textPrimary,
      ),
      child: Slider(
        value: value.toDouble(),
        max: max.toDouble(),
        onChanged: duration == Duration.zero
            ? null
            : (nextValue) =>
                  controller.seek(Duration(milliseconds: nextValue.round())),
      ),
    );

    if (!showTimes) {
      return slider;
    }

    return Column(
      children: [
        slider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(_formatDuration(position), style: _timeStyle),
              const Spacer(),
              Text(_formatDuration(duration), style: _timeStyle),
            ],
          ),
        ),
      ],
    );
  }

  static const _timeStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

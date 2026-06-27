import 'package:flutter/material.dart';

import '../controllers/player_controller.dart';
import '../services/app_audio_handler.dart';
import '../theme/app_theme.dart';

class PlaybackOptions extends StatelessWidget {
  const PlaybackOptions({required this.controller, super.key});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconOption(
                tooltip: _repeatTooltip(controller.repeatMode),
                icon: _repeatIcon(controller.repeatMode),
                indicator: _repeatIndicator(controller.repeatMode),
                isActive: controller.repeatMode != PlaybackRepeatMode.none,
                onTap: controller.cycleRepeatMode,
              ),
              const SizedBox(width: 18),
              _IconOption(
                tooltip: controller.shuffleEnabled ? '랜덤 켜짐' : '랜덤 꺼짐',
                icon: Icons.shuffle_rounded,
                indicator: controller.shuffleEnabled ? '' : null,
                isActive: controller.shuffleEnabled,
                onTap: () =>
                    controller.setShuffleEnabled(!controller.shuffleEnabled),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.card,
                    thumbColor: AppColors.textPrimary,
                  ),
                  child: Slider(
                    value: controller.speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    onChanged: controller.setSpeed,
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '${controller.speed.toStringAsFixed(1)}x',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _repeatIcon(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.none => Icons.repeat_rounded,
      PlaybackRepeatMode.one => Icons.repeat_one_rounded,
      PlaybackRepeatMode.all => Icons.repeat_rounded,
    };
  }

  String? _repeatIndicator(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.none => null,
      PlaybackRepeatMode.one => '1',
      PlaybackRepeatMode.all => '',
    };
  }

  String _repeatTooltip(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.none => '반복 꺼짐',
      PlaybackRepeatMode.one => '한 곡 반복',
      PlaybackRepeatMode.all => '전체 반복',
    };
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.tooltip,
    required this.icon,
    required this.indicator,
    required this.isActive,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final String? indicator;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.black : AppColors.textPrimary,
                ),
              ),
              if (indicator != null)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: indicator!.isEmpty ? 10 : 18,
                    height: indicator!.isEmpty ? 10 : 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: indicator!.isEmpty
                        ? null
                        : Text(
                            indicator!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'app_audio_handler.dart';

class PlayerSettings {
  const PlayerSettings({
    required this.repeatMode,
    required this.shuffleEnabled,
    required this.speed,
  });

  final PlaybackRepeatMode repeatMode;
  final bool shuffleEnabled;
  final double speed;
}

class PlayerSettingsStore {
  static const _repeatKey = 'player_repeat_mode';
  static const _shuffleKey = 'player_shuffle_enabled';
  static const _speedKey = 'player_speed';

  Future<PlayerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final repeatIndex = prefs.getInt(_repeatKey);
    final repeatMode =
        (repeatIndex != null &&
            repeatIndex >= 0 &&
            repeatIndex < PlaybackRepeatMode.values.length)
        ? PlaybackRepeatMode.values[repeatIndex]
        : PlaybackRepeatMode.none;

    return PlayerSettings(
      repeatMode: repeatMode,
      shuffleEnabled: prefs.getBool(_shuffleKey) ?? false,
      speed: prefs.getDouble(_speedKey) ?? 1.0,
    );
  }

  Future<void> saveRepeatMode(PlaybackRepeatMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_repeatKey, mode.index);
  }

  Future<void> saveShuffleEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shuffleKey, enabled);
  }

  Future<void> saveSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speedKey, speed);
  }
}

import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/app_audio_handler.dart';
import '../services/cover_art_service.dart';

class PlayerController extends ChangeNotifier {
  PlayerController(this._audioHandler) {
    _init();
  }

  final AppAudioHandler _audioHandler;
  List<Song> _library = [];
  List<Song> _songs = [];
  String? _activeCategory;
  bool _isReady = false;

  AppAudioHandler get audioHandler => _audioHandler;
  CoverArtService get coverArtService => _audioHandler.coverArtService;
  List<Song> get library => _library;
  List<Song> get songs => _songs;
  List<String> get categories {
    final values = _library.map((song) => song.category).toSet().toList();
    values.sort();
    return values;
  }

  String? get activeCategory => _activeCategory;
  int? get currentIndex {
    final playing = _audioHandler.playingSong;
    if (playing == null) {
      return null;
    }
    final index = _songs.indexWhere((song) => song.id == playing.id);
    return index >= 0 ? index : null;
  }

  Song? get currentSong => _audioHandler.playingSong;
  bool get isPlaying => _audioHandler.player.playing;
  bool get hasSongs => _songs.isNotEmpty;
  PlaybackRepeatMode get repeatMode => _audioHandler.repeatMode;
  bool get shuffleEnabled => _audioHandler.shuffleEnabled;
  double get speed => _audioHandler.speed;

  Future<void> _init() async {
    _audioHandler.currentIndexNotifier.addListener(notifyListeners);
    _audioHandler.settingsNotifier.addListener(notifyListeners);
    _audioHandler.player.playerStateStream.listen((_) {
      notifyListeners();
    });
    _audioHandler.player.positionStream.listen((_) => notifyListeners());
    _audioHandler.player.durationStream.listen((_) => notifyListeners());
    _isReady = true;
  }

  Future<void> setLibrary(List<Song> songs) async {
    _library = songs;
    await setCategory(null);
  }

  Future<void> setCategory(String? category) async {
    _activeCategory = category;
    _songs = category == null
        ? List.of(_library)
        : _library.where((song) => song.category == category).toList();
    await _audioHandler.updateFilteredSongs(_songs);
    notifyListeners();
  }

  Future<void> playSongAt(int index) async {
    if (!_isReady || index < 0 || index >= _songs.length) {
      return;
    }

    notifyListeners();
    await _audioHandler.playSongAtIndex(index);
  }

  Future<void> togglePlayPause() async {
    if (_audioHandler.player.playing) {
      await _audioHandler.pause();
      return;
    }

    if (_audioHandler.playingSong != null) {
      await _audioHandler.play();
      return;
    }

    if (_songs.isNotEmpty) {
      await playSongAt(0);
    }
  }

  Future<void> next() async {
    await _audioHandler.skipToNext();
  }

  Future<void> previous() async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> seek(Duration position) => _audioHandler.seek(position);

  Future<void> setSpeed(double speed) async {
    await _audioHandler.setSpeed(speed);
    notifyListeners();
  }

  void cycleRepeatMode() {
    final next = switch (repeatMode) {
      PlaybackRepeatMode.none => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.none,
    };
    _audioHandler.setAppRepeatMode(next);
    notifyListeners();
  }

  void setShuffleEnabled(bool enabled) {
    _audioHandler.setShuffleEnabled(enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioHandler.currentIndexNotifier.removeListener(notifyListeners);
    _audioHandler.settingsNotifier.removeListener(notifyListeners);
    super.dispose();
  }
}

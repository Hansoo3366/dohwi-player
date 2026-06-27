import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'audio_cache_service.dart';
import 'cover_art_service.dart';
import 'player_settings_store.dart';

enum PlaybackRepeatMode { none, one, all }

class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  AppAudioHandler._({
    required AudioCacheService cacheService,
    required CoverArtService coverArtService,
  }) : _cacheService = cacheService,
       _coverArtService = coverArtService {
    _loadPersistedSettings();
    _player.playbackEventStream.listen((event) {
      _broadcastPlaybackState(event);
    });
    _player.durationStream.listen((duration) {
      final song = currentSong;
      if (song != null && duration != null) {
        mediaItem.add(_toMediaItem(song, duration: duration));
      }
    });
    _player.playingStream.listen((playing) {
      _broadcastPlaybackState(_player.playbackEvent);
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleCompleted();
      }
    });
  }

  factory AppAudioHandler({
    AudioCacheService? cacheService,
    CoverArtService? coverArtService,
  }) {
    final cache = cacheService ?? AudioCacheService();
    return AppAudioHandler._(
      cacheService: cache,
      coverArtService: coverArtService ?? CoverArtService(),
    );
  }

  final AudioPlayer _player = AudioPlayer();
  final AudioCacheService _cacheService;
  final CoverArtService _coverArtService;
  final PlayerSettingsStore _settingsStore = PlayerSettingsStore();
  final currentIndexNotifier = ValueNotifier<int?>(null);
  final settingsNotifier = ValueNotifier<int>(0);
  final Random _random = Random();
  List<Song> _songs = [];
  Song? _playingSong;
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.none;
  bool _shuffleEnabled = false;
  double _speed = 1;
  int _loadSequence = 0;

  AudioPlayer get player => _player;
  AudioCacheService get cacheService => _cacheService;
  CoverArtService get coverArtService => _coverArtService;
  List<Song> get songs => List.unmodifiable(_songs);
  Song? get playingSong => _playingSong;
  int? get currentIndex => currentIndexNotifier.value;
  PlaybackRepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;
  double get speed => _speed;
  Song? get currentSong => _playingSong;

  Future<void> setSongs(List<Song> songs) async {
    await _player.stop();
    _songs = songs;
    _playingSong = null;
    currentIndexNotifier.value = null;
    queue.add(songs.map(_toMediaItem).toList(growable: false));
    mediaItem.add(null);
    _broadcastPlaybackState(_player.playbackEvent);
  }

  Future<void> updateFilteredSongs(List<Song> songs) async {
    _songs = songs;
    queue.add(songs.map(_toMediaItem).toList(growable: false));

    if (_playingSong != null) {
      final newIndex = songs.indexWhere((song) => song.id == _playingSong!.id);
      currentIndexNotifier.value = newIndex >= 0 ? newIndex : null;
    } else {
      currentIndexNotifier.value = null;
    }

    _broadcastPlaybackState(_player.playbackEvent);
  }

  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= _songs.length) {
      return;
    }

    final sequence = ++_loadSequence;
    final song = _songs[index];
    _playingSong = song;
    await _player.stop();
    currentIndexNotifier.value = index;
    mediaItem.add(_toMediaItem(song));
    _broadcastPlaybackState(_player.playbackEvent);

    try {
      final cachedPath = await _cacheService.getCachedPath(song);
      if (sequence != _loadSequence) {
        return;
      }

      if (cachedPath != null) {
        await _startPlayback(
          song: song,
          source: AudioSource.file(cachedPath),
          sequence: sequence,
        );
        return;
      }

      unawaited(_cacheSongInBackground(song));

      await _startPlayback(
        song: song,
        source: AudioSource.uri(song.audioUrl),
        sequence: sequence,
      );
    } catch (error, stackTrace) {
      debugPrint('Playback failed for ${song.id}: $error\n$stackTrace');
      if (sequence != _loadSequence) {
        return;
      }

      try {
        await _startPlayback(
          song: song,
          source: AudioSource.uri(song.audioUrl),
          sequence: sequence,
        );
      } catch (fallbackError, fallbackStackTrace) {
        debugPrint(
          'Fallback playback failed for ${song.id}: $fallbackError\n$fallbackStackTrace',
        );
      }
    }
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final settings = await _settingsStore.load();
      _repeatMode = settings.repeatMode;
      _shuffleEnabled = settings.shuffleEnabled;
      _speed = settings.speed;
      await _player.setSpeed(_speed);
      await _player.setLoopMode(
        _repeatMode == PlaybackRepeatMode.one ? LoopMode.one : LoopMode.off,
      );
      _notifySettingsChanged();
      _broadcastPlaybackState(_player.playbackEvent);
    } catch (error, stackTrace) {
      debugPrint('Failed to load player settings: $error\n$stackTrace');
    }
  }

  Future<void> _cacheSongInBackground(Song song) async {
    try {
      await _cacheService.cacheSong(song);
    } catch (error, stackTrace) {
      debugPrint('Background cache failed for ${song.id}: $error\n$stackTrace');
    }
  }

  Future<void> _startPlayback({
    required Song song,
    required AudioSource source,
    required int sequence,
  }) async {
    final duration = await _player.setAudioSource(
      source,
      initialPosition: Duration.zero,
    );
    if (sequence != _loadSequence) {
      return;
    }
    await _player.setSpeed(_speed);
    await _player.setLoopMode(
      _repeatMode == PlaybackRepeatMode.one ? LoopMode.one : LoopMode.off,
    );
    if (duration != null) {
      mediaItem.add(_toMediaItem(song, duration: duration));
    }
    _player.play(); // await 제거
  }

  @override
  Future<void> play() async {
    // 백그라운드 서비스가 멈추지 않도록 await 하지 않음
    _player.play();
  }

  @override
  Future<void> pause() async {
    _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _playingSong = null;
    currentIndexNotifier.value = null;
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    _player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0).toDouble();
    await _player.setSpeed(_speed);
    _notifySettingsChanged();
    _broadcastPlaybackState(_player.playbackEvent);
    unawaited(_settingsStore.saveSpeed(_speed));
  }

  void setAppRepeatMode(PlaybackRepeatMode mode) {
    _repeatMode = mode;
    _player.setLoopMode(
      _repeatMode == PlaybackRepeatMode.one ? LoopMode.one : LoopMode.off,
    );
    _notifySettingsChanged();
    unawaited(_settingsStore.saveRepeatMode(mode));
  }

  void setShuffleEnabled(bool enabled) {
    _shuffleEnabled = enabled;
    _notifySettingsChanged();
    unawaited(_settingsStore.saveShuffleEnabled(enabled));
  }

  @override
  Future<void> skipToNext() async {
    if (_songs.isEmpty) {
      return;
    }
    final nextIndex = _nextIndex(wrap: true);
    if (nextIndex == null) {
      return;
    }
    await playSongAtIndex(nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_songs.isEmpty) {
      return;
    }

    // 재생 중인 위치가 3초 이상이면 현재 곡을 처음부터 다시 재생
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }

    final previousIndex = _previousIndex();
    await playSongAtIndex(previousIndex);
  }

  Future<void> dispose() async {
    currentIndexNotifier.dispose();
    _cacheService.dispose();
    await _player.dispose();
  }

  Future<void> _handleCompleted() async {
    if (_songs.isEmpty) {
      return;
    }

    if (_repeatMode == PlaybackRepeatMode.one) {
      return;
    }

    final nextIndex = _nextIndex(wrap: _repeatMode == PlaybackRepeatMode.all);
    if (nextIndex == null) {
      await _player.pause();
      await _player.seek(Duration.zero);
      _broadcastPlaybackState(_player.playbackEvent);
      return;
    }

    await playSongAtIndex(nextIndex);
  }

  int? _nextIndex({required bool wrap}) {
    if (_songs.isEmpty) {
      return null;
    }

    if (_songs.length == 1) {
      return wrap ? 0 : null;
    }

    if (_shuffleEnabled) {
      var next = _random.nextInt(_songs.length);
      while (next == currentIndex) {
        next = _random.nextInt(_songs.length);
      }
      return next;
    }

    final next = (currentIndex ?? -1) + 1;
    if (next < _songs.length) {
      return next;
    }

    return wrap ? 0 : null;
  }

  int _previousIndex() {
    if (_songs.length <= 1) {
      return 0;
    }

    if (_shuffleEnabled) {
      var previous = _random.nextInt(_songs.length);
      while (previous == currentIndex) {
        previous = _random.nextInt(_songs.length);
      }
      return previous;
    }

    final current = currentIndex ?? 0;
    return current == 0 ? _songs.length - 1 : current - 1;
  }

  MediaItem _toMediaItem(Song song, {Duration? duration}) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist.isEmpty ? '도휘 플레이어' : song.artist,
      duration: duration ?? song.duration,
      artUri: song.coverUrl,
    );
  }

  void _broadcastPlaybackState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = _mapProcessingState(event.processingState);

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _speed,
        queueIndex: currentIndex,
      ),
    );
  }

  void _notifySettingsChanged() {
    settingsNotifier.value++;
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    return switch (state) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
  }
}

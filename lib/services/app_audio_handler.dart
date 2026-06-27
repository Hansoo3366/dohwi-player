import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

enum PlaybackRepeatMode { none, one, all }

class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  AppAudioHandler() {
    _player.playbackEventStream.listen(_broadcastPlaybackState);
    _player.durationStream.listen((duration) {
      final song = currentSong;
      if (song != null && duration != null) {
        mediaItem.add(_toMediaItem(song, duration: duration));
      }
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleCompleted();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final currentIndexNotifier = ValueNotifier<int?>(null);
  final settingsNotifier = ValueNotifier<int>(0);
  final Random _random = Random();
  List<Song> _songs = [];
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.none;
  bool _shuffleEnabled = false;
  double _speed = 1;
  int _loadSequence = 0;

  AudioPlayer get player => _player;
  List<Song> get songs => List.unmodifiable(_songs);
  int? get currentIndex => currentIndexNotifier.value;
  PlaybackRepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;
  double get speed => _speed;
  Song? get currentSong {
    final index = currentIndex;
    if (index == null || index < 0 || index >= _songs.length) {
      return null;
    }
    return _songs[index];
  }

  Future<void> setSongs(List<Song> songs) async {
    await _player.stop();
    _songs = songs;
    currentIndexNotifier.value = null;
    queue.add(songs.map(_toMediaItem).toList(growable: false));
    mediaItem.add(null);
    _broadcastPlaybackState(_player.playbackEvent);
  }

  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= _songs.length) {
      return;
    }

    final sequence = ++_loadSequence;
    final song = _songs[index];
    await _player.stop();
    currentIndexNotifier.value = index;
    mediaItem.add(_toMediaItem(song));
    _broadcastPlaybackState(_player.playbackEvent);

    final duration = await _player.setAudioSource(
      AudioSource.uri(song.audioUrl),
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
    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0).toDouble();
    await _player.setSpeed(_speed);
    _notifySettingsChanged();
    _broadcastPlaybackState(_player.playbackEvent);
  }

  void setAppRepeatMode(PlaybackRepeatMode mode) {
    _repeatMode = mode;
    _player.setLoopMode(
      _repeatMode == PlaybackRepeatMode.one ? LoopMode.one : LoopMode.off,
    );
    _notifySettingsChanged();
  }

  void setShuffleEnabled(bool enabled) {
    _shuffleEnabled = enabled;
    _notifySettingsChanged();
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
    final previousIndex = _previousIndex();
    await playSongAtIndex(previousIndex);
  }

  Future<void> dispose() async {
    currentIndexNotifier.dispose();
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
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
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

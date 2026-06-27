import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';

class CoverArtService extends ChangeNotifier {
  final Map<String, Uint8List> _covers = {};
  Directory? _cacheDir;
  bool _initialized = false;

  Uint8List? coverFor(String songId) => _covers[songId];

  Future<void> init() async {
    if (_initialized) return;
    final baseDir = await getApplicationCacheDirectory();
    _cacheDir = Directory(p.join(baseDir.path, 'cover_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    _initialized = true;
  }

  Future<Uint8List?> getCachedCover(String songId) async {
    await init();
    final file = File(p.join(_cacheDir!.path, '$songId.webp'));
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<void> saveCoverToCache(String songId, Uint8List bytes) async {
    await init();
    final file = File(p.join(_cacheDir!.path, '$songId.webp'));
    await file.writeAsBytes(bytes);
  }

  void loadFromSongs(List<Song> songs) {
    var changed = false;
    for (final song in songs) {
      final bytes = song.embeddedCoverBytes;
      if (bytes != null && !_covers.containsKey(song.id)) {
        _covers[song.id] = bytes;
        saveCoverToCache(song.id, bytes); // Save to disk in background
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }
}

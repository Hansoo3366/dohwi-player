import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../models/song.dart';

class AudioCacheService {
  AudioCacheService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  Directory? _cacheDir;
  Map<String, _CacheEntry> _index = {};
  final Map<String, Future<String>> _inflightDownloads = {};
  bool _initialized = false;

  Future<String?> getCachedPath(Song song) async {
    await _ensureInitialized();

    final cachedPath = _index[song.id]?.path;
    if (cachedPath != null) {
      final cachedFile = File(cachedPath);
      if (await cachedFile.exists() && await cachedFile.length() > 0) {
        await _touchEntry(song.id);
        return cachedPath;
      }
      _index.remove(song.id);
      await _saveIndex();
    }

    final existingFile = _fileForSong(song);
    if (await existingFile.exists() && await existingFile.length() > 0) {
      final size = await existingFile.length();
      _index[song.id] = _CacheEntry(
        songId: song.id,
        path: existingFile.path,
        sizeBytes: size,
        lastAccessedMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _saveIndex();
      return existingFile.path;
    }

    return null;
  }

  Future<String> cacheSong(Song song) async {
    final cachedPath = await getCachedPath(song);
    if (cachedPath != null) {
      return cachedPath;
    }

    return _inflightDownloads.putIfAbsent(
      song.id,
      () => _downloadSong(song).whenComplete(
        () => _inflightDownloads.remove(song.id),
      ),
    );
  }

  Future<int> getCacheSizeBytes() async {
    await _ensureInitialized();
    return _index.values.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
  }

  Future<void> clearCache() async {
    await _ensureInitialized();

    for (final entry in _index.values) {
      final file = File(entry.path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _index.clear();
    await _saveIndex();
  }

  void dispose() {
    _client.close();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    final baseDir = await getApplicationCacheDirectory();
    _cacheDir = Directory(p.join(baseDir.path, 'audio_cache'));
    await _cacheDir!.create(recursive: true);
    await _loadIndex();
    _initialized = true;
  }

  Future<void> _loadIndex() async {
    final indexFile = _indexFile;
    if (!await indexFile.exists()) {
      _index = {};
      return;
    }

    try {
      final decoded = jsonDecode(await indexFile.readAsString());
      if (decoded is! Map<String, dynamic>) {
        _index = {};
        return;
      }

      _index = decoded.map(
        (key, value) => MapEntry(
          key,
          _CacheEntry.fromJson(key, value),
        ),
      );
    } catch (_) {
      _index = {};
    }
  }

  Future<void> _saveIndex() async {
    final payload = _index.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _indexFile.writeAsString(jsonEncode(payload));
  }

  File get _indexFile => File(p.join(_cacheDir!.path, 'index.json'));

  Future<String> _downloadSong(Song song) async {
    final destination = _fileForSong(song);
    final tempFile = File('${destination.path}.tmp');

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final request = http.Request('GET', song.audioUrl);
    final response = await _client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AudioCacheException(
        '음원 다운로드 실패: HTTP ${response.statusCode}',
      );
    }

    final contentLength = response.contentLength ?? 0;
    if (contentLength > 0) {
      await _ensureSpaceFor(contentLength);
    }

    final sink = tempFile.openWrite();
    var downloadedBytes = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
      }
    } finally {
      await sink.close();
    }

    if (downloadedBytes == 0) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw const AudioCacheException('다운로드한 음원 파일이 비어 있습니다.');
    }

    await _ensureSpaceFor(downloadedBytes);

    if (await destination.exists()) {
      await destination.delete();
    }
    await tempFile.rename(destination.path);

    _index[song.id] = _CacheEntry(
      songId: song.id,
      path: destination.path,
      sizeBytes: downloadedBytes,
      lastAccessedMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveIndex();

    return destination.path;
  }

  Future<void> _ensureSpaceFor(int incomingBytes) async {
    var currentSize = await getCacheSizeBytes();
    while (currentSize + incomingBytes > AppConfig.maxAudioCacheBytes &&
        _index.isNotEmpty) {
      final oldestEntry = _index.values.reduce(
        (a, b) => a.lastAccessedMs <= b.lastAccessedMs ? a : b,
      );
      final file = File(oldestEntry.path);
      if (await file.exists()) {
        await file.delete();
      }
      currentSize -= oldestEntry.sizeBytes;
      _index.remove(oldestEntry.songId);
    }
    await _saveIndex();
  }

  Future<void> _touchEntry(String songId) async {
    final entry = _index[songId];
    if (entry == null) {
      return;
    }

    _index[songId] = entry.copyWith(
      lastAccessedMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveIndex();
  }

  File _fileForSong(Song song) {
    final extension = _extensionFromUrl(song.audioUrl);
    final safeId = _safeFileName(song.id);
    return File(p.join(_cacheDir!.path, '$safeId$extension'));
  }

  String _safeFileName(String songId) {
    final sanitized = songId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return sanitized.isEmpty ? 'song' : sanitized;
  }

  String _extensionFromUrl(Uri url) {
    final lowerPath = url.path.toLowerCase();
    for (final extension in ['.mp3', '.m4a', '.aac', '.wav', '.ogg']) {
      if (lowerPath.endsWith(extension)) {
        return extension;
      }
    }
    return '.mp3';
  }
}

class _CacheEntry {
  const _CacheEntry({
    required this.songId,
    required this.path,
    required this.sizeBytes,
    required this.lastAccessedMs,
  });

  final String songId;
  final String path;
  final int sizeBytes;
  final int lastAccessedMs;

  factory _CacheEntry.fromJson(String songId, Object? json) {
    if (json is! Map<String, dynamic>) {
      throw FormatException('Invalid cache entry for $songId');
    }

    return _CacheEntry(
      songId: songId,
      path: json['path'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      lastAccessedMs: (json['lastAccessedMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'sizeBytes': sizeBytes,
      'lastAccessedMs': lastAccessedMs,
    };
  }

  _CacheEntry copyWith({int? lastAccessedMs}) {
    return _CacheEntry(
      songId: songId,
      path: path,
      sizeBytes: sizeBytes,
      lastAccessedMs: lastAccessedMs ?? this.lastAccessedMs,
    );
  }
}

class AudioCacheException implements Exception {
  const AudioCacheException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/song.dart';

class SongRepository {
  SongRepository({http.Client? client, FirebaseStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? FirebaseStorage.instance;

  final http.Client _client;
  final FirebaseStorage _storage;

  Future<List<Song>> fetchSongs() async {
    final storageSongs = await _fetchFirebaseStorageSongs();
    if (storageSongs.isNotEmpty) {
      return storageSongs;
    }

    try {
      final uri = Uri.parse(AppConfig.songsJsonUrl);
      final response = await _client.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SongRepositoryException('서버 응답 오류: ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const SongRepositoryException('songs.json 형식이 올바르지 않습니다.');
      }

      final songs = decoded
          .whereType<Map<String, dynamic>>()
          .map(_tryParseSong)
          .whereType<Song>()
          .where((song) => song.enabled)
          .toList(growable: false);

      if (songs.isEmpty) {
        throw const SongRepositoryException('재생할 수 있는 곡이 없습니다.');
      }

      return songs;
    } catch (_) {
      return demoSongs;
    }
  }

  Future<List<Song>> _fetchFirebaseStorageSongs() async {
    try {
      final folderRef = _storage.ref(AppConfig.firebaseSongsFolder);
      final result = await folderRef.listAll();
      final fileRefs =
          result.items
              .where((ref) => _isSupportedAudio(ref.name))
              .toList(growable: false)
            ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

      final songs = <Song>[];
      for (final ref in fileRefs) {
        final url = await ref.getDownloadURL();
        final audioUrl = Uri.parse(url);
        songs.add(
          Song(
            id: _songIdFromPath(ref.fullPath),
            title: _titleFromFileName(ref.name),
            artist: '도휘 플레이어',
            category: AppConfig.firebaseSongsCategory,
            audioUrl: audioUrl,
            embeddedCoverBytes: await _tryReadEmbeddedCoverFromStorage(ref),
          ),
        );
      }

      return songs;
    } catch (_) {
      return const [];
    }
  }

  Future<Uint8List?> _tryReadEmbeddedCoverFromStorage(Reference ref) async {
    try {
      final bytes = await ref.getData(AppConfig.maxEmbeddedCoverReadBytes);
      if (bytes == null) {
        return null;
      }
      return _extractId3Cover(bytes);
    } catch (_) {
      return null;
    }
  }

  Uint8List? _extractId3Cover(Uint8List bytes) {
    if (bytes.length < 20 ||
        bytes[0] != 0x49 ||
        bytes[1] != 0x44 ||
        bytes[2] != 0x33) {
      return null;
    }

    final version = bytes[3];
    if (version != 3 && version != 4) {
      return null;
    }

    final tagSize =
        ((bytes[6] & 0x7F) << 21) |
        ((bytes[7] & 0x7F) << 14) |
        ((bytes[8] & 0x7F) << 7) |
        (bytes[9] & 0x7F);
    final tagEnd = (10 + tagSize).clamp(10, bytes.length);

    var offset = 10;
    while (offset + 10 <= tagEnd) {
      final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final frameSize = version == 4
          ? ((bytes[offset + 4] & 0x7F) << 21) |
                ((bytes[offset + 5] & 0x7F) << 14) |
                ((bytes[offset + 6] & 0x7F) << 7) |
                (bytes[offset + 7] & 0x7F)
          : (bytes[offset + 4] << 24) |
                (bytes[offset + 5] << 16) |
                (bytes[offset + 6] << 8) |
                bytes[offset + 7];

      if (frameId.trim().isEmpty || frameSize <= 0) {
        break;
      }

      final payloadStart = offset + 10;
      final payloadEnd = (payloadStart + frameSize).clamp(payloadStart, tagEnd);
      if (frameId == 'APIC') {
        return _extractImageBytes(bytes.sublist(payloadStart, payloadEnd));
      }

      offset = payloadEnd;
    }

    return null;
  }

  Uint8List? _extractImageBytes(Uint8List payload) {
    final jpgStart = _indexOfBytes(payload, [0xFF, 0xD8, 0xFF]);
    if (jpgStart != -1) {
      final jpgEnd = _lastIndexOfBytes(payload, [0xFF, 0xD9]);
      if (jpgEnd > jpgStart) {
        return Uint8List.fromList(payload.sublist(jpgStart, jpgEnd + 2));
      }
    }

    final pngStart = _indexOfBytes(payload, [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    if (pngStart != -1) {
      final pngEnd = _indexOfBytes(payload, [
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);
      if (pngEnd > pngStart) {
        return Uint8List.fromList(payload.sublist(pngStart, pngEnd + 8));
      }
    }

    final webpStart = _indexOfBytes(payload, [0x52, 0x49, 0x46, 0x46]);
    if (webpStart != -1 && webpStart + 12 < payload.length) {
      final hasWebp =
          payload[webpStart + 8] == 0x57 &&
          payload[webpStart + 9] == 0x45 &&
          payload[webpStart + 10] == 0x42 &&
          payload[webpStart + 11] == 0x50;
      if (hasWebp) {
        final size =
            payload[webpStart + 4] |
            (payload[webpStart + 5] << 8) |
            (payload[webpStart + 6] << 16) |
            (payload[webpStart + 7] << 24);
        final end = (webpStart + 8 + size).clamp(webpStart, payload.length);
        return Uint8List.fromList(payload.sublist(webpStart, end));
      }
    }

    return null;
  }

  int _indexOfBytes(Uint8List bytes, List<int> pattern) {
    for (var i = 0; i <= bytes.length - pattern.length; i++) {
      var matched = true;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return i;
      }
    }
    return -1;
  }

  int _lastIndexOfBytes(Uint8List bytes, List<int> pattern) {
    for (var i = bytes.length - pattern.length; i >= 0; i--) {
      var matched = true;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return i;
      }
    }
    return -1;
  }

  bool _isSupportedAudio(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg');
  }

  String _songIdFromPath(String fullPath) {
    return fullPath
        .toLowerCase()
        .replaceAll(RegExp(r'\.[a-z0-9]+$'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _titleFromFileName(String fileName) {
    final withoutExtension = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final cleaned = withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? fileName : cleaned;
  }

  Song? _tryParseSong(Map<String, dynamic> json) {
    try {
      return Song.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

class SongRepositoryException implements Exception {
  const SongRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

final demoSongs = [
  Song(
    id: 'demo-001',
    title: '데모 노래 1',
    artist: 'SoundHelix',
    category: 'A 만화 노래',
    audioUrl: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ),
    coverUrl: Uri.parse('https://picsum.photos/seed/kids-music-1/512/512'),
  ),
  Song(
    id: 'demo-002',
    title: '데모 노래 2',
    artist: 'SoundHelix',
    category: 'A 만화 노래',
    audioUrl: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    coverUrl: Uri.parse('https://picsum.photos/seed/kids-music-2/512/512'),
  ),
  Song(
    id: 'demo-003',
    title: '데모 노래 3',
    artist: 'SoundHelix',
    category: 'B 만화 노래',
    audioUrl: Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
    coverUrl: Uri.parse('https://picsum.photos/seed/kids-music-3/512/512'),
  ),
];

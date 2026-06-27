import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import '../models/song.dart';
import '../utils/id3_cover_extractor.dart';

class SongRepository {
  SongRepository({
    http.Client? client,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: AppConfig.firestoreDatabaseId);

  final http.Client _client;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<List<Song>> fetchSongs() async {
    final firestoreSongs = await _fetchFirestoreSongs();
    if (firestoreSongs.isNotEmpty) {
      return firestoreSongs;
    }

    if (AppConfig.useStorageFolderFallback) {
      final storageSongs = await _fetchFirebaseStorageSongs();
      if (storageSongs.isNotEmpty) {
        return storageSongs;
      }
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

  Future<List<Song>> _fetchFirestoreSongs() async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.firestoreSongsCollection)
          .get();

      if (snapshot.docs.isEmpty) {
        return const [];
      }

      final songs = <Song>[];
      for (final doc in snapshot.docs) {
        final song = await _songFromFirestoreDoc(doc);
        if (song != null) {
          songs.add(song);
        }
      }

      songs.sort(_compareSongs);
      return songs;
    } catch (_) {
      return const [];
    }
  }

  Future<Song?> _songFromFirestoreDoc(DocumentSnapshot doc) async {
    final data = doc.data();
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final enabled = data['enabled'] is bool ? data['enabled'] as bool : true;
    if (!enabled) {
      return null;
    }

    final id = _readString(data['id']) ?? doc.id;
    final title = _readString(data['title']);
    if (title == null) {
      return null;
    }

    final audioPath = _readString(data['audioPath']);
    final coverPath = _readString(data['coverPath']);
    final audioUrlValue = _readString(data['audioUrl']);
    Uri? audioUrl;
    Uri? coverUrl;

    if (audioPath != null) {
      // Storage URL을 직접 생성하여 네트워크 요청(getDownloadURL)을 생략합니다.
      final encodedPath = Uri.encodeComponent(audioPath);
      audioUrl = Uri.parse('https://firebasestorage.googleapis.com/v0/b/dohwi-player.firebasestorage.app/o/$encodedPath?alt=media');
    } else if (audioUrlValue != null) {
      audioUrl = Uri.tryParse(audioUrlValue);
    }

    if (audioUrl == null) {
      return null;
    }

    if (coverPath != null) {
      final encodedCoverPath = Uri.encodeComponent(coverPath);
      coverUrl = Uri.parse('https://firebasestorage.googleapis.com/v0/b/dohwi-player.firebasestorage.app/o/$encodedCoverPath?alt=media');
    }

    final durationSeconds = data['durationSeconds'];
    final coverUrlValue = _readString(data['coverUrl']);
    if (coverUrl == null && coverUrlValue != null) {
      coverUrl = Uri.tryParse(coverUrlValue);
    }

    return Song(
      id: id,
      title: title,
      artist: _readString(data['artist']) ?? '도휘 플레이어',
      category: _readString(data['category']) ?? '기본',
      audioUrl: audioUrl,
      coverUrl: coverUrl,
      embeddedCoverBytes: null, // 서버에서 추출하므로 로컬 추출은 더 이상 사용하지 않음
      duration: durationSeconds is num
          ? Duration(seconds: durationSeconds.round())
          : null,
      enabled: true,
    );
  }

  int _compareSongs(Song a, Song b) {
    return a.category.compareTo(b.category) != 0
        ? a.category.compareTo(b.category)
        : a.title.compareTo(b.title);
  }

  Future<List<Song>> _fetchFirebaseStorageSongs() async {
    try {
      final songs = <Song>[];

      for (final source in AppConfig.storageFolderFallback) {
        final folderSongs = await _fetchSongsFromFolder(
          folder: source.folder,
          category: source.category,
        );
        songs.addAll(folderSongs);
      }

      songs.sort((a, b) => a.title.compareTo(b.title));
      return songs;
    } catch (_) {
      return const [];
    }
  }

  Future<List<Song>> _fetchSongsFromFolder({
    required String folder,
    required String category,
  }) async {
    try {
      final folderRef = _storage.ref(folder);
      final result = await folderRef.listAll();
      final fileRefs =
          result.items
              .where((ref) => _isSupportedAudio(ref.name))
              .toList(growable: false)
            ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

      return Future.wait(
        fileRefs.map((ref) async {
          final urlFuture = ref.getDownloadURL();
          final coverFuture = _fetchEmbeddedCoverFromStorage(ref);
          final url = await urlFuture;
          final audioUrl = Uri.parse(url);
          final coverBytes =
              await coverFuture ?? await _fetchEmbeddedCoverFromUrl(audioUrl);
          return Song(
            id: _songIdFromPath(ref.fullPath),
            title: _titleFromFileName(ref.name),
            artist: '도휘 플레이어',
            category: category,
            audioUrl: audioUrl,
            embeddedCoverBytes: coverBytes,
          );
        }),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<Uint8List?> _fetchEmbeddedCoverFromStorage(Reference ref) async {
    try {
      final bytes = await ref.getData(AppConfig.maxCoverHeaderBytes);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return Id3CoverExtractor.fromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _fetchEmbeddedCoverFromUrl(Uri audioUrl) async {
    try {
      final end = AppConfig.maxCoverHeaderBytes - 1;
      final request = http.Request('GET', audioUrl)
        ..headers['Range'] = 'bytes=0-$end';
      final response = await _client.send(request);
      if (response.statusCode != 206 && response.statusCode != 200) {
        return null;
      }

      final bytes = await http.ByteStream(response.stream).toBytes();
      if (bytes.isEmpty) {
        return null;
      }
      return Id3CoverExtractor.fromBytes(bytes);
    } catch (_) {
      return null;
    }
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
    final normalized = fullPath.trim().toLowerCase();
    final encoded = base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
    return 'fs-$encoded';
  }

  String _titleFromFileName(String fileName) {
    final withoutExtension = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final cleaned = withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? fileName : cleaned;
  }

  String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

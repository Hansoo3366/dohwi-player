import 'dart:typed_data';

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.artist = '',
    this.category = 'General',
    this.coverUrl,
    this.embeddedCoverBytes,
    this.duration,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String artist;
  final String category;
  final Uri audioUrl;
  final Uri? coverUrl;
  final Uint8List? embeddedCoverBytes;
  final Duration? duration;
  final bool enabled;

  factory Song.fromJson(Map<String, dynamic> json) {
    final id = _readString(json['id']);
    final title = _readString(json['title']);
    final audioValue = _readString(json['audioUrl']);
    final audioUrl = audioValue == null ? null : Uri.tryParse(audioValue);

    if (id == null || title == null || audioUrl == null) {
      throw const FormatException('곡에는 id, title, audioUrl이 필요합니다.');
    }

    final coverValue = _readString(json['coverUrl']);
    final durationSeconds = json['durationSeconds'];

    return Song(
      id: id,
      title: title,
      artist: _readString(json['artist']) ?? '',
      category: _readString(json['category']) ?? '기본',
      audioUrl: audioUrl,
      coverUrl: coverValue == null ? null : Uri.tryParse(coverValue),
      duration: durationSeconds is num
          ? Duration(seconds: durationSeconds.round())
          : null,
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
    );
  }

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

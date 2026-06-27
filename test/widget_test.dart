import 'package:flutter_test/flutter_test.dart';
import 'package:kids_music_player/models/song.dart';

void main() {
  test('Song.fromJson parses required fields', () {
    final song = Song.fromJson({
      'id': 'song-001',
      'title': 'Test Song',
      'artist': 'Kids',
      'category': 'A Cartoon Songs',
      'audioUrl': 'https://example.com/song.mp3',
      'coverUrl': 'https://example.com/cover.webp',
      'durationSeconds': 90,
      'enabled': true,
    });

    expect(song.id, 'song-001');
    expect(song.title, 'Test Song');
    expect(song.artist, 'Kids');
    expect(song.category, 'A Cartoon Songs');
    expect(song.duration, const Duration(seconds: 90));
    expect(song.enabled, isTrue);
  });
}

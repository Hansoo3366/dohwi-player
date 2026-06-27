class AppConfig {
  static const songsJsonUrl = 'https://example.com/songs.json';

  /// Firestore 곡 메타데이터 컬렉션
  static const firestoreSongsCollection = 'songs';
  static const firestoreDatabaseId = 'song-list';

  /// Firestore에 곡이 없을 때 Storage 폴더 스캔 fallback (마이그레이션용)
  static const useStorageFolderFallback = true;
  static const storageFolderFallback = [
    StorageFolderFallback(folder: 'dooli', category: '둘리'),
  ];

  static const maxCoverHeaderBytes = 1024 * 1024; // 1MB로 줄여서 초기 로딩 속도 대폭 향상
  static const maxAudioCacheBytes = 500 * 1024 * 1024;
}

class StorageFolderFallback {
  const StorageFolderFallback({required this.folder, required this.category});

  final String folder;
  final String category;
}

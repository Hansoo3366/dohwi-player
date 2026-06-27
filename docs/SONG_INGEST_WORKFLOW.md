# Song Ingest Workflow

## 1. What This Script Does

`tools/prepare_song_assets.js` prepares legally obtained local audio files for Firebase.

It does this:

- Copies local audio files into a Firebase Storage staging folder
- Copies local cover files into a Firebase Storage staging folder
- Generates Firestore song documents
- Keeps the original source URL as metadata

It does not download or extract audio from YouTube links.

## 2. Input File

Create a JSON file based on:

```text
tools/song_sources.example.json
```

Each item should include:

```json
{
  "id": "a-cartoon-001",
  "title": "Song title",
  "artist": "Kids",
  "category": "A Cartoon Songs",
  "audioSourcePath": "local-media/audio/a-cartoon-001.mp3",
  "coverSourcePath": "local-media/covers/a-cartoon-001.webp",
  "durationSeconds": 120,
  "enabled": true,
  "sortOrder": 1,
  "sourceUrl": "https://www.youtube.com/watch?v=example"
}
```

## 3. Run

```bash
node tools/prepare_song_assets.js tools/song_sources.json
```

Optional custom output paths:

```bash
node tools/prepare_song_assets.js tools/song_sources.json build/firebase-upload build/firestore
```

## 4. Output

Storage staging files:

```text
build/firebase-upload/audio/{category}/{song-id}.mp3
build/firebase-upload/covers/{category}/{song-id}.webp
```

Firestore data:

```text
build/firestore/songs.json
build/firestore/songs.firestore-batch.json
```

## 5. Upload

Upload the contents of `build/firebase-upload` to Firebase Storage.

The generated Firestore document uses relative paths like:

```text
audio/a-cartoon-songs/a-cartoon-001.mp3
covers/a-cartoon-songs/a-cartoon-001.webp
```

Those paths should match the uploaded Storage paths.


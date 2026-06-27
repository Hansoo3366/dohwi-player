const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const mm = require('music-metadata');
const sharp = require('sharp');
const os = require('os');
const path = require('path');
const fs = require('fs');

initializeApp();

const db = getFirestore('song-list');
const storage = getStorage();
const bucket = storage.bucket('dohwi-player.firebasestorage.app');
const SONGS_COLLECTION = 'songs';
const CATEGORIES_COLLECTION = 'categories';
const AUDIO_EXTENSIONS = new Set(['.mp3', '.m4a', '.aac', '.wav', '.ogg']);

function isSupportedAudio(fileName) {
  const lower = fileName.toLowerCase();
  for (const extension of AUDIO_EXTENSIONS) {
    if (lower.endsWith(extension)) {
      return true;
    }
  }
  return false;
}

function songIdFromStoragePath(storagePath) {
  const normalized = storagePath.trim().toLowerCase();
  return `fs-${Buffer.from(normalized, 'utf8').toString('base64url').replace(/=/g, '')}`;
}

function titleFromFileName(fileName) {
  const withoutExtension = fileName.replace(/\.[^.]+$/, '');
  const cleaned = withoutExtension
    .replace(/[_-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return cleaned.length > 0 ? cleaned : fileName;
}

function parseStorageObject(object) {
  const storagePath = object.name;
  if (!storagePath || object.name.endsWith('/')) {
    return null;
  }

  const segments = storagePath.split('/').filter(Boolean);
  if (segments.length < 2) {
    return null;
  }

  const fileName = segments[segments.length - 1];
  if (!isSupportedAudio(fileName)) {
    return null;
  }

  const folder = segments[0];
  return {
    storagePath,
    folder,
    fileName,
    songId: songIdFromStoragePath(storagePath),
    title: titleFromFileName(fileName),
  };
}

async function resolveCategoryLabel(folder) {
  const snapshot = await db.collection(CATEGORIES_COLLECTION).doc(folder).get();
  if (!snapshot.exists) {
    return folder;
  }

  const data = snapshot.data() || {};
  if (typeof data.label === 'string' && data.label.trim().length > 0) {
    return data.label.trim();
  }

  return folder;
}

const functions = require('firebase-functions/v1');

exports.syncSongOnUpload = functions
  .region('asia-northeast3')
  .storage
  .bucket('dohwi-player.firebasestorage.app')
  .object()
  .onFinalize(async (object) => {
  const parsed = parseStorageObject(object);
  if (!parsed) {
    return;
  }

  const category = await resolveCategoryLabel(parsed.folder);
  const songRef = db.collection(SONGS_COLLECTION).doc(parsed.songId);

  const tempFilePath = path.join(os.tmpdir(), parsed.fileName);
  let coverPath = null;
  let title = parsed.title;
  let artist = '도휘 플레이어';

  try {
    await bucket.file(parsed.storagePath).download({ destination: tempFilePath });
    const metadata = await mm.parseFile(tempFilePath);
    
    if (metadata.common.title) title = metadata.common.title;
    if (metadata.common.artist) artist = metadata.common.artist;

    const picture = metadata.common.picture && metadata.common.picture[0];
    if (picture) {
      coverPath = `covers/${parsed.songId}.webp`;
      const coverFile = bucket.file(coverPath);
      const webpBuffer = await sharp(picture.data).webp({ quality: 80 }).toBuffer();
      await coverFile.save(webpBuffer, {
        metadata: { contentType: 'image/webp' }
      });
    }
  } catch (e) {
    functions.logger.error('Error extracting metadata', e);
  } finally {
    if (fs.existsSync(tempFilePath)) {
      fs.unlinkSync(tempFilePath);
    }
  }

  await songRef.set(
    {
      id: parsed.songId,
      title: title,
      artist: artist,
      category,
      audioPath: parsed.storagePath,
      coverPath: coverPath,
      enabled: true,
      sortOrder: Date.now(),
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  functions.logger.info('Synced song document', {
    songId: parsed.songId,
    audioPath: parsed.storagePath,
    coverPath,
    category,
  });
});

exports.syncSongOnDelete = functions
  .region('asia-northeast3')
  .storage
  .bucket('dohwi-player.firebasestorage.app')
  .object()
  .onDelete(async (object) => {
  const parsed = parseStorageObject(object);
  if (!parsed) {
    return;
  }

  const songRef = db.collection(SONGS_COLLECTION).doc(parsed.songId);
  await songRef.set(
    {
      enabled: false,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  functions.logger.info('Disabled song document', {
    songId: parsed.songId,
    audioPath: parsed.storagePath,
  });
});

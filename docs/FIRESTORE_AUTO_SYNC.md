# Storage 업로드 → Firestore 자동 동기화

Storage에 mp3를 올리면 Cloud Function이 Firestore `songs` 문서를 자동 생성/수정합니다.

## 동작

| Storage 경로 | Firestore |
|---|---|
| `dooli/노래1.mp3` 업로드 | `songs/{자동 id}` 문서 생성 |
| 같은 파일 다시 업로드 | 문서 갱신 (`merge`) |
| Storage에서 파일 삭제 | `enabled: false` 처리 |

## 카테고리(필터) 이름

폴더 이름과 앱 필터 이름을 연결하려면 Firestore `categories` 컬렉션을 사용합니다.

```json
// categories/dooli
{
  "label": "둘리"
}
```

```json
// categories/anpanman
{
  "label": "호빵맨"
}
```

`categories` 문서가 없으면 **폴더 이름 그대로** 필터에 표시됩니다.

## 생성되는 song 문서 예시

Storage에 `dooli/둘리테마.mp3` 업로드 시:

```json
{
  "id": "fs-....",
  "title": "둘리테마",
  "artist": "도휘 플레이어",
  "category": "둘리",
  "audioPath": "dooli/둘리테마.mp3",
  "enabled": true,
  "sortOrder": 1710000000000
}
```

앱은 `audioPath`로 Storage URL을 받고, 앨범아rt는 mp3 embed에서 추출합니다.

## 배포 (최초 1회)

1. Firebase **Blaze(종량제)** 요금제 필요 (Cloud Functions)
2. Node.js 20 설치
3. 프로젝트 루트에서:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions,firestore:rules
```

## 배포 에러 해결

### `storage.buckets.get` denied / Eventarc permission

Storage 트리거 배포 시 Eventarc 서비스 계정에 Storage 권한이 필요합니다.

**Google Cloud Console (UI):**

1. [Cloud Storage](https://console.cloud.google.com/storage/browser?project=dohwi-player) → `dohwi-player.firebasestorage.app` 버킷
2. **권한(Permissions)** 탭 → **주 구성원 추가**
3. 주 구성원:

```text
service-168771327351@gcp-sa-eventarc.iam.gserviceaccount.com
```

4. 역할: **Storage 객체 뷰어** (Storage Object Viewer)
5. 저장 후 1~2분 뒤 다시 `firebase deploy --only functions`

**gcloud CLI:**

```bash
gcloud storage buckets add-iam-policy-binding gs://dohwi-player.firebasestorage.app --member=serviceAccount:service-168771327351@gcp-sa-eventarc.iam.gserviceaccount.com --role=roles/storage.objectViewer

gcloud projects add-iam-policy-binding dohwi-player --member=serviceAccount:service-168771327351@gcp-sa-eventarc.iam.gserviceaccount.com --role=roles/eventarc.serviceAgent
```

### IAM policy modify failed (첫 배포)

프로젝트 **소유자(Owner)** 계정으로 배포하거나, Firebase CLI가 출력한 `gcloud projects add-iam-policy-binding ...` 명령 4개를 Owner가 실행합니다.

## 사용 방법

1. Firebase Console → Storage → `dooli/`, `anpanman/` 같은 **폴더에 mp3 업로드**
2. Functions 로그에서 `Synced song document` 확인
3. Firestore `songs` 컬렉션에 문서 생성 확인
4. 앱 재실행 → 목록 반영

## 주의

- Storage 경로는 **`{폴더}/{파일}.mp3`** 형태여야 합니다. (루트에 바로 올린 파일은 무시)
- mp3 / m4a / aac / wav / ogg만 처리합니다.
- 앱의 `useStorageFolderFallback`은 Firestore가 비어 있을 때만 사용됩니다. Functions 배포 후 Firestore를 우선 사용하세요.

# 재생 옵션, 카테고리, Firebase 명세

## 1. 재생 큐 기준

앱은 전체 라이브러리와 현재 재생 큐를 구분한다.

- `All`: 전체 곡을 현재 재생 큐로 사용
- `A Cartoon Songs`: A 만화 노래만 현재 재생 큐로 사용
- `B Cartoon Songs`: B 만화 노래만 현재 재생 큐로 사용
- 이후 카테고리는 서버/Firebase 데이터의 `category` 값 기준으로 자동 확장

사용자가 카테고리를 바꾸면 현재 재생 큐도 해당 카테고리로 바뀐다.

## 2. 재생 옵션

### 배속

- 범위: `0.5x` ~ `2.0x`
- 단위: `0.25x`
- 현재 재생 중인 곡에 즉시 적용

### 반복

반복 모드는 세 가지다.

- 반복 없음
- 한 곡 반복
- 전체 반복

반복 없음 상태에서 현재 큐의 마지막 곡이 끝나면 재생을 멈춘다.

### 랜덤 섞기

- 상태: 온 / 오프
- 켜져 있으면 다음곡 선택 시 현재 재생 큐 안에서 랜덤으로 선택한다.
- 특정 카테고리가 선택되어 있으면 해당 카테고리 안에서만 랜덤 재생한다.

## 3. 곡 데이터 필드

```json
{
  "id": "song-001",
  "title": "Song title",
  "artist": "Kids",
  "category": "A Cartoon Songs",
  "audioUrl": "https://example.com/audio/song-001.mp3",
  "coverUrl": "https://example.com/covers/song-001.webp",
  "durationSeconds": 120,
  "enabled": true
}
```

`category`가 없으면 앱은 `General`로 처리한다.

## 4. Firebase 사용 계획

Firebase는 다음 역할로 사용한다.

- Firebase Storage: 음원 파일 저장
- Firebase Storage: 커버 이미지 저장
- Cloud Firestore 또는 Realtime Database: 곡 메타데이터 저장

권장 구조는 Firestore 컬렉션 `songs`를 두는 방식이다.

```text
songs/{songId}
  title
  artist
  category
  audioPath 또는 audioUrl
  coverPath 또는 coverUrl
  durationSeconds
  enabled
  sortOrder
  createdAt
  updatedAt
```

1차 구현은 JSON URL 기반으로 유지하고, 다음 단계에서 `SongRepository`만 Firebase 기반으로 교체한다.

UI, 플레이어 컨트롤러, 오디오 핸들러는 같은 `Song` 모델을 계속 사용한다.

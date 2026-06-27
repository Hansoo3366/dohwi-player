# 서버 음원 목록 명세서

## 1. 개요

앱은 서버에 있는 JSON 파일을 읽어 곡 목록을 구성한다. 서버는 별도 API 서버일 수도 있고, 정적 파일 호스팅일 수도 있다.

1차 버전에서는 단순성을 위해 정적 JSON 파일 방식을 기준으로 한다.

## 2. 엔드포인트

### GET `/songs.json`

곡 목록을 반환한다.

예시 URL:

```text
https://example.com/songs.json
```

## 3. 응답 형식

응답은 JSON 배열이다.

```json
[
  {
    "id": "song-001",
    "title": "노래 제목",
    "artist": "아티스트",
    "audioUrl": "https://example.com/audio/song-001.mp3",
    "coverUrl": "https://example.com/covers/song-001.webp",
    "durationSeconds": 120,
    "enabled": true
  }
]
```

## 4. 필드 정의

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `id` | string | 필수 | 곡 고유 ID |
| `title` | string | 필수 | 곡 제목 |
| `artist` | string | 선택 | 아티스트 또는 분류명 |
| `audioUrl` | string | 필수 | 음원 파일 URL |
| `coverUrl` | string | 선택 | 커버 이미지 URL |
| `durationSeconds` | number | 선택 | 곡 길이, 초 단위 |
| `enabled` | boolean | 선택 | `false`면 앱에서 숨김 |

## 5. 서버 파일 구조 예시

```text
public/
  songs.json
  audio/
    song-001.mp3
    song-002.mp3
  covers/
    song-001.webp
    song-002.webp
```

## 6. 검증 규칙

앱은 다음 규칙으로 데이터를 처리한다.

- `id`, `title`, `audioUrl`이 없는 항목은 무시한다.
- `enabled`가 `false`인 항목은 표시하지 않는다.
- `artist`가 없으면 빈 문자열 또는 기본값을 사용한다.
- `coverUrl`이 없거나 이미지 로딩에 실패하면 기본 커버를 사용한다.
- `durationSeconds`가 없으면 플레이어가 음원 메타데이터에서 길이를 읽도록 한다.

## 7. HTTP 요구사항

- HTTPS 사용을 권장한다.
- `Content-Type`은 `application/json`을 권장한다.
- 음원 파일은 앱에서 직접 접근 가능해야 한다.
- 파일 URL은 리다이렉트가 과도하지 않아야 한다.

## 8. 예시 전체 JSON

```json
[
  {
    "id": "kids-001",
    "title": "첫 번째 노래",
    "artist": "Kids",
    "audioUrl": "https://example.com/audio/kids-001.mp3",
    "coverUrl": "https://example.com/covers/kids-001.webp",
    "durationSeconds": 95,
    "enabled": true
  },
  {
    "id": "kids-002",
    "title": "두 번째 노래",
    "artist": "Kids",
    "audioUrl": "https://example.com/audio/kids-002.mp3",
    "coverUrl": "https://example.com/covers/kids-002.webp",
    "durationSeconds": 132,
    "enabled": true
  }
]
```

## 9. 추후 확장 후보

JSON 형식은 아래 필드를 추가할 수 있게 여지를 둔다.

- `category`: 카테고리
- `album`: 앨범명
- `sortOrder`: 정렬 순서
- `lyricsUrl`: 가사 URL
- `tags`: 검색/분류용 태그
- `requiresAuth`: 인증 필요 여부


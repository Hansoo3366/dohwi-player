# 구현 명세서

## 1. 앱 아키텍처

1차 버전은 단순한 계층 구조로 구현한다.

```text
UI Layer
  screens, widgets

State / Controller Layer
  player controller

Service Layer
  song repository
  audio service

Model Layer
  song model
```

## 2. 권장 폴더 구조

```text
lib/
  main.dart
  app.dart
  config/
    app_config.dart
  models/
    song.dart
  repositories/
    song_repository.dart
  services/
    audio_handler.dart
  controllers/
    player_controller.dart
  screens/
    home_screen.dart
    player_screen.dart
  widgets/
    song_tile.dart
    mini_player.dart
    player_controls.dart
    cover_art.dart
```

## 3. 설정값

### AppConfig

```dart
class AppConfig {
  static const songsJsonUrl = 'https://example.com/songs.json';
}
```

초기 개발 중에는 이 URL만 교체해서 서버를 변경한다.

## 4. Song 모델

서버 JSON을 앱 내부 모델로 변환한다.

필수 필드가 없는 항목은 모델 생성 단계에서 실패시키고 목록에서 제외한다.

```dart
class Song {
  final String id;
  final String title;
  final String artist;
  final Uri audioUrl;
  final Uri? coverUrl;
  final Duration? duration;
  final bool enabled;
}
```

## 5. SongRepository

역할:

- 서버에서 JSON 요청
- JSON 파싱
- 잘못된 항목 제거
- `enabled == false` 항목 제거
- 앱에서 사용할 `List<Song>` 반환

오류:

- 네트워크 실패
- JSON 파싱 실패
- 유효한 곡이 없음

## 6. PlayerController

역할:

- 현재 재생 목록 관리
- 현재 곡 인덱스 관리
- 재생/일시정지/다음/이전 명령 제공
- UI가 구독할 재생 상태 제공

1차 버전에서는 복잡한 상태관리 패키지를 쓰지 않고 `ChangeNotifier` 또는 `ValueNotifier` 기반으로 시작해도 충분하다.

## 7. AudioHandler

`audio_service`와 `just_audio`를 연결한다.

역할:

- 백그라운드 재생 유지
- Android 알림창 미디어 컨트롤 표시
- 잠금화면 메타데이터 제공
- 다음곡/이전곡/재생/일시정지 명령 처리

## 8. UI 원칙

UI 디자인은 루트의 `DESIGN-spotify.md`를 기준으로 구현한다.

- 버튼은 크고 명확하게 만든다.
- 아이가 자주 누르는 컨트롤은 화면 하단에 배치한다.
- 텍스트만 의존하지 않고 커버 이미지를 함께 표시한다.
- 화면 이동은 최소화한다.
- 설정/관리 기능은 1차 버전에서 숨긴다.

### 디자인 시스템 적용 기준

- 기본 배경은 `#121212`를 사용한다.
- 주요 표면은 `#181818`, `#1f1f1f`, `#252525` 계열을 사용한다.
- 기본 텍스트는 `#ffffff`, 보조 텍스트는 `#b3b3b3`를 사용한다.
- 주요 재생 버튼과 활성 상태에는 `#1ed760`을 사용한다.
- 초록색은 장식용으로 쓰지 않고 재생, 활성 상태, 주요 CTA에만 사용한다.
- 버튼은 pill 형태를 기본으로 하고, 재생 버튼은 원형으로 만든다.
- 앨범/커버 이미지가 화면의 주된 색상 요소가 되도록 한다.
- 하단 now-playing bar는 모든 주요 화면에서 유지한다.
- 모바일 우선으로 구성하되, 태블릿 이상에서는 목록/플레이어 영역 확장을 고려한다.

## 9. 에러 처리 정책

### 곡 목록 로딩 실패

- 오류 메시지 표시
- 다시 시도 버튼 표시

### 일부 곡 데이터 오류

- 해당 곡만 제외
- 전체 앱은 정상 실행

### 음원 재생 실패

- 안내 메시지 표시
- 다음 곡 자동 이동은 1차 버전에서는 선택 사항

## 10. Android 권한

원격 음원 스트리밍을 위해 인터넷 권한이 필요하다.

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

백그라운드 재생과 알림 컨트롤은 사용하는 패키지 설정에 맞춰 Android manifest 설정을 추가한다.

## 11. 빌드 타입

### 개발 테스트

```powershell
flutter build apk --debug
```

### 가족 전달용

```powershell
flutter build apk --release
```

릴리즈 APK를 장기적으로 배포하려면 keystore를 만들어 서명 정보를 고정하는 것이 좋다.

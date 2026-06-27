# 개발 로드맵

## 1. 현재 상태

- 프로젝트 폴더는 준비되어 있다.
- 기초 기획 문서가 작성되어 있다.
- 현재 PC에는 `flutter`와 `dart` 명령어가 설치되어 있지 않다.

## 2. 개발 전 준비

### Flutter SDK 설치

Windows에서 Flutter SDK를 설치하고 PATH에 등록해야 한다.

설치 확인 명령:

```powershell
flutter --version
dart --version
flutter doctor
```

### Android 빌드 환경

APK 빌드를 위해 아래 항목이 필요하다.

- Android Studio
- Android SDK
- Android SDK Platform Tools
- Android SDK Build Tools
- Android Emulator 또는 실제 Android 기기

확인 명령:

```powershell
flutter doctor
```

## 3. 1차 개발 순서

### Step 1. Flutter 프로젝트 생성

```powershell
flutter create .
```

또는 별도 앱 이름을 지정한다.

```powershell
flutter create --project-name kids_music_player .
```

### Step 2. 패키지 추가

```powershell
flutter pub add just_audio audio_service audio_session http cached_network_image
```

### Step 3. 폴더 구조 구성

```text
lib/
  main.dart
  app.dart
  models/
    song.dart
  services/
    song_repository.dart
    audio_player_service.dart
  screens/
    home_screen.dart
    player_screen.dart
  widgets/
    song_tile.dart
    mini_player.dart
```

### Step 4. 서버 JSON 연동

- `Song` 모델 작성
- `SongRepository` 작성
- 서버 `songs.json` 요청
- 잘못된 항목 필터링

### Step 5. 기본 UI 구현

- 홈 화면
- 곡 목록
- 로딩/오류/빈 목록 상태
- 미니 플레이어

### Step 6. 스트리밍 재생 구현

- `just_audio` 연결
- 곡 선택 재생
- 재생/일시정지
- 다음/이전
- 재생 위치 표시

### Step 7. 백그라운드 재생 구현

- `audio_service` 연결
- Android 알림창 미디어 컨트롤
- 잠금화면 컨트롤

### Step 8. APK 빌드

디버그 APK:

```powershell
flutter build apk --debug
```

릴리즈 APK:

```powershell
flutter build apk --release
```

## 4. 테스트 체크리스트

- 앱 실행 시 곡 목록이 표시되는가
- 네트워크가 꺼져 있을 때 오류 화면이 나오는가
- 곡을 누르면 재생되는가
- 다음곡/이전곡이 정상 동작하는가
- 화면을 꺼도 음악이 계속 재생되는가
- 알림창에서 일시정지/재생이 되는가
- APK를 다른 Android 기기에 설치할 수 있는가

## 5. 산출물

1차 개발 완료 시 산출물은 다음과 같다.

- Flutter 프로젝트 소스
- 서버 JSON 샘플
- Android APK 파일
- 설치 안내 문서


# Windows Flutter 설치 안내

## 1. 결론

VS Code 확장프로그램만 설치해서는 Flutter 앱을 빌드할 수 없다.

필요한 구성은 다음과 같다.

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- VS Code Flutter 확장프로그램

Dart SDK는 Flutter SDK에 포함되어 있으므로 Flutter를 설치하면 보통 별도로 Dart를 설치하지 않아도 된다.

## 2. 추천 설치 순서

### Step 1. VS Code 설치

이미 설치되어 있다면 건너뛴다.

### Step 2. VS Code 확장프로그램 설치

VS Code Extensions에서 아래 확장프로그램을 설치한다.

- Flutter
- Dart

Flutter 확장프로그램을 설치하면 Dart 확장도 함께 설치되는 경우가 많다.

### Step 3. Flutter SDK 설치

Flutter 공식 문서의 Windows 설치 안내를 따른다.

설치 후 PowerShell에서 확인한다.

```powershell
flutter --version
dart --version
```

둘 다 버전이 출력되어야 한다.

### Step 4. Android Studio 설치

APK 빌드를 위해 Android Studio와 Android SDK가 필요하다.

Android Studio 설치 후 SDK Manager에서 다음 항목을 확인한다.

- Android SDK Platform
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android Emulator
- Android SDK Command-line Tools

### Step 5. Flutter Doctor 확인

PowerShell에서 실행한다.

```powershell
flutter doctor
```

문제가 있으면 출력에 나온 안내를 따라 해결한다.

Android 라이선스 관련 안내가 나오면 보통 아래 명령을 실행한다.

```powershell
flutter doctor --android-licenses
```

## 3. 설치 완료 후 프로젝트 생성

현재 프로젝트 폴더에서 실행한다.

```powershell
flutter create --project-name kids_music_player .
```

패키지를 추가한다.

```powershell
flutter pub add just_audio audio_service audio_session http cached_network_image
```

앱 실행 확인:

```powershell
flutter run
```

APK 빌드:

```powershell
flutter build apk --release
```

## 4. 설치 확인 체크리스트

- `flutter --version`이 동작한다.
- `dart --version`이 동작한다.
- `flutter doctor`에서 Android toolchain 문제가 해결되어 있다.
- Android Studio가 설치되어 있다.
- 실제 Android 기기 또는 에뮬레이터가 준비되어 있다.


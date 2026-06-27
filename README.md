# 도휘 플레이어

도휘를 위한 Android 음악 플레이어 앱입니다. Firebase Storage에 올린 음원을 읽어서 스트리밍으로 재생하며, APK 파일로 직접 설치하는 방식을 기준으로 합니다.

## 다운로드

### APK

APK 파일은 GitHub 저장소에 커밋하지 않습니다. GitHub는 100MB가 넘는 파일을 일반 Git push로 받지 않기 때문에, APK는 **GitHub Releases의 Assets**에 첨부합니다.

로컬에서 생성된 APK 예시:

```text
releases/latest/도휘 플레이어.apk
```

GitHub 배포 시에는 이 파일을 Release assets에 직접 업로드하세요.

### Source Code

소스코드는 GitHub의 초록색 **Code** 버튼 또는 Release 페이지의 **Source code (zip)** 으로 받을 수 있습니다.

## 버전 관리

Flutter 앱 버전은 `pubspec.yaml`의 `version` 값으로 관리합니다.

현재 버전:

```yaml
version: 1.0.0+1
```

형식:

```text
앱버전+빌드번호
```

예시:

```yaml
version: 1.0.1+2
```

배포할 때 추천 순서:

1. `pubspec.yaml`의 `version`을 올린다.
2. APK를 빌드한다.
3. GitHub에서 `v1.0.1` 같은 Release 태그를 만든다.
4. APK를 Release assets에 첨부한다.

## 주요 기능

- Firebase Storage 폴더에서 곡 목록 읽기
- 원격 음원 스트리밍 재생
- MP3 내장 앨범 커버 표시
- 카테고리별 재생 큐
- 배속 조절
- 반복 재생
- 랜덤 재생
- 백그라운드 재생 구조
- Android 미디어 알림/잠금화면 컨트롤 구조

## Firebase Storage

현재 앱은 Firebase Storage의 아래 폴더를 우선 읽습니다.

```text
gs://dohwi-player.firebasestorage.app/dooli
```

지원 확장자:

```text
.mp3, .m4a, .aac, .wav, .ogg
```

Storage Rules는 앱에서 읽기만 가능하게 설정하면 됩니다.

```js
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

Flutter Web으로 테스트할 때 Storage CORS 오류가 나면 [Firebase Storage CORS 설정](docs/FIREBASE_STORAGE_CORS.md)을 참고하세요.

## 문서

- [디자인 시스템 명세서](DESIGN-spotify.md)
- [제품 기획서](docs/PRODUCT_BRIEF.md)
- [기능 요구사항 명세서](docs/REQUIREMENTS.md)
- [구현 명세서](docs/IMPLEMENTATION_SPEC.md)
- [재생 옵션/Firebase 명세](docs/PLAYBACK_AND_FIREBASE_SPEC.md)
- [Firebase CLI 설정](docs/FIREBASE_CLI_SETUP.md)
- [Firebase Storage CORS 설정](docs/FIREBASE_STORAGE_CORS.md)
- [APK 전달 및 설치 안내](docs/APK_DISTRIBUTION.md)

## 개발/검증

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

빌드 결과:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

현재 빌드 시 `audio_session`, `firebase_storage` 플러그인의 Kotlin Gradle Plugin 마이그레이션 경고가 표시될 수 있습니다. APK 생성은 정상 동작합니다.

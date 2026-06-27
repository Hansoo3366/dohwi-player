# Firebase Storage CORS 설정

## 원인

Flutter Web으로 실행하면 앱의 origin은 보통 아래처럼 localhost가 된다.

```text
http://localhost:10641
```

Firebase Storage 파일은 아래 도메인에서 내려온다.

```text
https://firebasestorage.googleapis.com
```

브라우저는 서로 다른 origin의 파일 fetch를 CORS 정책으로 막을 수 있다. 이 경우 콘솔에 아래와 같은 오류가 표시된다.

```text
No 'Access-Control-Allow-Origin' header is present
```

Android APK에서는 브라우저 CORS가 적용되지 않는다. 하지만 웹에서 개발 테스트하려면 Storage 버킷 CORS 설정이 필요하다.

## 설정 파일

프로젝트 루트에 CORS 설정 파일이 있다.

```text
firebase-storage-cors.json
```

## 적용 명령

Google Cloud CLI가 설치되어 있다면:

```bash
gcloud storage buckets update gs://dohwi-player.firebasestorage.app --cors-file=firebase-storage-cors.json
```

구버전 `gsutil`을 사용한다면:

```bash
gsutil cors set firebase-storage-cors.json gs://dohwi-player.firebasestorage.app
```

적용 후 Flutter Web dev server를 재시작한다.

```bash
flutter run -d chrome
```

## 확인

브라우저 콘솔에서 `No 'Access-Control-Allow-Origin'` 오류가 사라져야 한다.


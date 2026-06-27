# Firebase CLI / FlutterFire CLI 설정

## 1. 필요한 CLI

FlutterFire 설정에는 두 가지 CLI가 모두 필요하다.

- Firebase CLI: `firebase`
- FlutterFire CLI: `flutterfire`

FlutterFire CLI만 설치하면 `flutterfire configure`가 실패한다.

## 2. 설치 상태

현재 확인된 실행 파일 위치:

```text
C:\Users\awaol\AppData\Roaming\npm\firebase.cmd
C:\Users\awaol\AppData\Local\Pub\Cache\bin\flutterfire.bat
```

## 3. Git Bash 임시 PATH 설정

Git Bash에서 아래 명령을 먼저 실행한다.

```bash
export PATH="$PATH:/c/Users/awaol/AppData/Roaming/npm:/c/Users/awaol/AppData/Local/Pub/Cache/bin"
```

확인:

```bash
firebase --version
flutterfire.bat --version
```

Git Bash에서는 `flutterfire` 대신 `flutterfire.bat`로 실행하는 것이 가장 확실하다.

## 4. 로그인

```bash
firebase login
```

브라우저가 열리면 Firebase 프로젝트를 사용할 Google 계정으로 로그인한다.

## 5. FlutterFire 설정

```bash
flutterfire.bat configure --project=dohwi-player
```

프로젝트 ID가 아직 Firebase에 없으면 Firebase Console에서 먼저 만들거나, CLI가 묻는 생성 절차를 따른다.

## 6. 영구 PATH 설정

Git Bash에서 계속 쓰려면 `~/.bashrc`에 추가한다.

```bash
echo 'export PATH="$PATH:/c/Users/awaol/AppData/Roaming/npm:/c/Users/awaol/AppData/Local/Pub/Cache/bin"' >> ~/.bashrc
source ~/.bashrc
```


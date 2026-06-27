# 디자인 구현 메모

## 1. 기준 문서

앱 UI는 루트의 `DESIGN-spotify.md`를 기준으로 구현한다.

이 문서는 Flutter 구현 시 특히 자주 참조할 핵심 규칙만 요약한다.

## 2. 핵심 방향

- 어두운 배경 위에 콘텐츠와 커버 이미지가 돋보이는 음악 플레이어 UI
- 아이가 누르기 쉬운 큰 컨트롤
- 하단 now-playing bar 중심의 앱 구조
- 재생 버튼과 활성 상태에만 초록색 강조 사용

## 3. Flutter 테마 토큰 후보

```dart
class AppColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF181818);
  static const surfaceAlt = Color(0xFF1F1F1F);
  static const card = Color(0xFF252525);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3);
  static const accent = Color(0xFF1ED760);
  static const error = Color(0xFFF3727F);
  static const warning = Color(0xFFFFA42B);
  static const info = Color(0xFF539DF5);
}
```

## 4. 주요 컴포넌트

### 재생 버튼

- 원형
- 배경: `#1ed760`
- 아이콘: 검정 또는 아주 어두운 색
- 화면에서 가장 명확한 CTA

### 일반 버튼

- pill 형태
- 배경: `#1f1f1f`
- 텍스트: 흰색
- 라벨은 가능하면 짧게 유지

### 곡 카드/목록

- 표면: `#181818` 또는 `#1f1f1f`
- 현재 재생 중인 곡은 초록색 텍스트 또는 작은 활성 표시로 구분
- 커버 이미지는 6px radius

### 하단 미니 플레이어

- 모든 주요 화면 하단에 고정
- 현재 곡 커버, 제목, 재생/일시정지 버튼 제공
- 배경은 `#181818`
- 상단에 미묘한 구분선 또는 그림자 사용

## 5. 주의사항

- 밝은 배경을 메인 화면에 쓰지 않는다.
- 초록색을 배경 장식으로 넓게 쓰지 않는다.
- 카드 안에 카드를 중첩하지 않는다.
- 아이가 쓰는 앱이므로 컨트롤 터치 영역은 작게 만들지 않는다.
- 텍스트 설명을 과도하게 넣지 말고, 아이콘과 커버 중심으로 구성한다.


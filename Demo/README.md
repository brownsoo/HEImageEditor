# HEImageEditor Demo

`HEImageEditor` / `HEImagePicker` 라이브러리를 시뮬레이터에서 바로 확인하기 위한 최소 데모 앱입니다.
로컬 SwiftPM 패키지(상위 디렉터리)를 직접 참조합니다.

## 기능

- **샘플 이미지 편집** — 코드로 생성한 그라데이션 이미지를 `HEEditImageViewController.showImageEditor(...)` 로 편집합니다. 모든 `EditTool` 을 활성화합니다. (Draw / Clip / ImageSticker / TextSticker / MosaicDraw / Filter / Adjust)
  - 이미지 스티커는 외부 에셋 없이 이모지를 `UIImage` 로 렌더링해 제공합니다. (`EmojiStickerDataSource`)
  - 특수 스티커인 **얼굴 AI**(`faceAI`, 얼굴 인식 후 이모지 자동 배치)와 **모자이크**(`mosaic`)도 함께 노출합니다.
- **사진 피커 열기** — `HEImagePicker` 로 사진/동영상을 선택합니다. 선택한 첫 사진을 미리보기에 표시합니다.
  - 피커의 **"사진 편집"** 을 누르면(`didSelectToEditItem`) 선택한 사진이 곧바로 이미지 에디터로 연결됩니다.

## 실행

Xcode 로 열기:

```bash
open Demo/HEImageEditorDemo.xcodeproj
```

명령줄에서 빌드 + 시뮬레이터 설치/실행:

```bash
# 고정 derivedDataPath 로 빌드 (기기 이름에 의존하지 않도록 generic 대상 사용)
xcodebuild build \
  -project Demo/HEImageEditorDemo.xcodeproj \
  -scheme HEImageEditorDemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData

# 시뮬레이터 부팅 후, 방금 빌드한 산출물 경로에서 설치/실행
xcrun simctl boot 'iPhone 17 Pro' 2>/dev/null || true
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/HEImageEditorDemo.app
xcrun simctl launch booted com.heimageeditor.demo
```

> 사진 피커는 시뮬레이터의 사진 접근 권한을 요청합니다. 권한 설명 문자열은 빌드 설정(`INFOPLIST_KEY_NSPhotoLibraryUsageDescription`)에 포함되어 있습니다.

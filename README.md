# HEImageEditor

> Now developing..

HEImageEditor was created based on [ZLImageEditor](https://github.com/longitachi/ZLImageEditor), [YPImagePicker](https://github.com/Yummypets/YPImagePicker).
I improved functionality and added several features✨.


### <a id="Editing Features"></a>이미지 편집 
- Free draw line.
- Free draw mosaic line.
- Crop & Rotate.
- Image sticker
  - Automatically attach stickers to your face through facial recognition.✨
- Text sticker
  - Custom text color & Background color✨
- Mosaic sticker ✨ 
  - You can attach the mosaic effect like a sticker and change its size and position.
- Filter (Support custom filters).
- Adjust (Brightness, Contrast, Saturation).
- Multiple Images supports.✨

### <a id="Picking Features"></a>이미지 또는 비디오 피커
- Pick media source


### <a id="Requirements"></a>Requirements
 * Swift 5.8+
 * Xcode 15+
 * Target iOS 14.0

### <a id="Usage"></a>Usage
```swift
var imageStickers: [HEImageSticker] = []
// 에디터 세팅 
func configImageEditor() {
    // 이미지 스티커를 사용하려면, HEImageStickerTray 를 구현해줘야 한다.
    let stickerTray = HEImageStickerTrayView()
    // 이미지 스티커용 이미지 데이터 소스 제공 
    stickerTray.dataSource = self
    
    imageStickers.append(HEImageSticker.faceAiIcon) // 얼굴인식 스티커 추가
    imageStickers.append(HEImageSticker.mosaicIcon) // 모자이크 스티커 추가 
    imageStickers.append(contentsOf: (1...18).map { (v) -> String in
        "imageSticker" + String(v)
    }.compactMap { name in
        HEImageSticker(id: name) {
            UIImage(named: name) ?? UIImage()
        }
    })
    
    // 편집기 구성 
    HEConfiguration.default()
        .clipRatios([.origin, .custom, .wh1x1])
        .imageStickerTray(stickerTray)
}
```

```swift
// 단일 이미지를 편집 
func startEditSingleImage(_ image: UIImage, editState: HEEditState?) {
    HEEditImageViewController.showImageEditor(
        parent: self,
        image: image,
        editState: editState,
        delegate: self,
        topToolViewBuilder: makeTopToolBuilder(),
        clipImageBottomViewBuilder: { clipView in // 자르기&회전 이외의 뷰를 추가할 수 있음.
            let bottom = HEClipBottomView()
            bottom.cancelClickListener = { [weak clipView] in clipView?.cancelEdit() }
            bottom.doneClickListener = { [weak clipView] in clipView?.doneEdit() }
            bottom.revertClickListener = { [weak clipView] in clipView?.revertEdit() }
            return (bottom, HEClipBottomView.estimateHeight)
        }
    )
}
```
```swift
// 다수 이미지를 편집하고 싶다면, 이미지 스토어 생성 
lazy var imageStore = HESimpleImageStore()

func startEditMultipleImages(_ images: [HEImage]) {
    imageStore.clearAll()
    imageStore.addHEImages(images)
    let vc = HEImageEditorViewController(imageStore: imageStore,
                                        imageCache: imageStore,
                                        stickerDataSource: self)
    
    vc.modalPresentationStyle = .overFullScreen
    present(vc, animated: true)
}
```
```swift
// 이미지/비디오 피커 열기 (전체 화면 권장)
func openPicker() {
    let picker = HEImagePicker()
    picker.pickerDelegate = self
    picker.modalPresentationStyle = .fullScreen
    present(picker, animated: true)
}
```

### <a id="Demo"></a>Demo
`Demo/HEImageEditorDemo.xcodeproj` 를 열면 시뮬레이터에서 에디터와 피커를 바로 확인할 수 있습니다.
모든 편집 툴, 이모지·얼굴 AI·모자이크 이미지 스티커, 사진 피커가 구성되어 있습니다.
자세한 실행 방법은 [Demo/README.md](Demo/README.md) 를 참고하세요.

### <a id="Languages"></a>Languages
🇺🇸 English, 🇰🇷 Korean


### Swift Package Manager
1. Select File > Swift Packages > Add Package Dependency. Enter https://github.com/brownsoo/HEImageEditor.git in the "Choose Package Repository" dialog.
2. After Xcode checking out the source and resolving the version, you can choose the "HEImageEditor" library and add it to your app target.


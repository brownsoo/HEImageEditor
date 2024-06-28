
HEImageEditor 는 [ZLImageEditor](https://github.com/longitachi/ZLImageEditor) 를 수정하여 만들었습니다.  

### <a id="Features"></a>Features
- [x] Draw (Support custom line color).
- [x] Crop (Support custom crop ratios).
- [x] Image sticker (Support custom image sticker container view).
- [x] Text sticker  (Support custom text color).
- [x] Mosaic sticker.
- [x] Mosaic drawing.
- [x] Filter (Support custom filters).
- [x] Adjust (Brightness, Contrast, Saturation).

### <a id="Requirements"></a>Requirements
 * Swift 5.x
 * Xcode 12.x

### <a id="Usage"></a>Usage
```swift
// 이미지 스티커 제공자 
var imageStickers: [HEImageSticker] = []
// 에디터 세팅 
func configImageEditor() {
    
    let stickerTray = HEImageStickerTrayView()
    stickerTray.dataSource = self
    
    imageStickers.append(HEImageSticker.faceAiIcon)
    imageStickers.append(HEImageSticker.mosaicIcon)
    imageStickers.append(contentsOf: (1...18).map { (v) -> String in
        "imageSticker" + String(v)
    }.compactMap { name in
        HEImageSticker(id: name) {
            UIImage(named: name) ?? UIImage()
        }
    })
    
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
        clipImageBottomViewBuilder: { clipView in
            let bottom = HEClipBottomView()
            bottom.cancelClickListener = { [weak clipView] in clipView?.cancelEdit() }
            bottom.doneClickListener = { [weak clipView] in clipView?.doneEdit() }
            bottom.revertClickListener = { [weak clipView] in clipView?.revertEdit() }
            return (bottom, HEClipBottomView.estimateHeight)
        }
    )
}


// 다수  이미지를 편집하고 싶다면, 이미지 스토어 생성 
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

### <a id="Languages"></a>Languages
🇺🇸 English, 🇰🇷 Korean


### Swift Package Manager
1. Select File > Swift Packages > Add Package Dependency. Enter https://github.com/brownsoo/HEImageEditor.git in the "Choose Package Repository" dialog.
2. After Xcode checking out the source and resolving the version, you can choose the "HEImageEditor" library and add it to your app target.

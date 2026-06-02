//
//  EmojiStickerDataSource.swift
//  HEImageEditorDemo
//
//  이미지 스티커(EditTool.imageSticker)를 외부 에셋 없이 확인할 수 있도록
//  이모지를 UIImage 로 렌더링해 스티커로 제공하는 데모용 데이터 소스입니다.
//

import UIKit
import HEImageEditor

/// 이모지를 정사각형 UIImage 로 렌더링하는 헬퍼.
enum EmojiImageRenderer {

    /// 이모지가 차지하는 비율(여백 확보용).
    private static let glyphRatio: CGFloat = 0.8

    /// 이모지를 스티커 원본 크기의 투명 배경 이미지로 그린다.
    static func image(from emoji: String) -> UIImage {
        let size = HEImageSticker.defaultImageRawSize
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let font = UIFont.systemFont(ofSize: size.height * glyphRatio)
            let attributed = NSAttributedString(string: emoji, attributes: [.font: font])
            let textSize = attributed.size()
            attributed.draw(at: CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            ))
        }
    }
}

/// 이모지 기반 이미지 스티커 데이터 소스.
///
/// `HEImageStickerTrayView.dataSource` 는 weak 참조이므로,
/// 이 인스턴스는 호출부에서 강하게 보유해야 한다.
final class EmojiStickerDataSource: NSObject, HEImageStickerTrayViewDataSource {

    private static let emojis = [
        "😀", "😎", "😍", "🥳", "😭", "🤩", "👍", "🙏", "🔥", "🎉",
        "❤️", "⭐️", "🌈", "🍎", "🐶", "🐱", "🚀", "⚽️", "🎸", "💎",
    ]

    /// 일반 이모지 스티커. 얼굴 인식(faceAI) 배치 시에도 이 목록에서 무작위로 선택된다.
    private static let emojiStickers: [HEImageSticker] = emojis.map { emoji in
        HEImageSticker(id: emoji) {
            EmojiImageRenderer.image(from: emoji)
        }
    }

    /// 특수 스티커(얼굴 AI, 모자이크) + 일반 이모지 스티커.
    private let stickers: [HEImageSticker] =
        [HEImageSticker.faceAiIcon, HEImageSticker.mosaicIcon] + emojiStickers

    func hasMosaicSticker(_ trayView: HEImageStickerTrayView) -> Bool {
        true
    }

    func imageStickerTrayView(
        _ trayView: HEImageStickerTrayView,
        numberOfItemsInSection section: Int
    ) -> Int {
        stickers.count
    }

    func imageStickerTrayView(
        _ trayView: HEImageStickerTrayView,
        stickerForItemAt indexPath: IndexPath
    ) -> HEImageSticker {
        stickers[indexPath.item]
    }

    /// 얼굴 위에 올릴 후보 스티커. 특수 스티커를 제외한 일반 이모지에서 무작위 선택된다.
    func allStickersOnFace(_ trayView: HEImageStickerTrayView) -> [HEImageSticker] {
        Self.emojiStickers
    }
}

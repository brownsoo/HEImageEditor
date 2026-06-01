//
//  EditorLocalizationTests.swift
//  HEImageEditorTests
//
//  정적 검사: HEImageEditorLocalizable 키가 모두 해석되는지 검증(로케일 비의존).
//

import XCTest
@testable import HEImageEditor

final class EditorLocalizationTests: XCTestCase {

    private let keys: [String] = [
        "complete pick", "custom ratio", "circle ratio", "original", "rotate",
        "cancel", "done", "confirm", "editFinish", "revert",
        "brightness", "contrast", "saturation", "hudProcessing",
        "text_input_placeholder",
        "effect-draw", "effect-clip", "effect-imageSticker", "effect-textSticker",
        "effect-mosaicDraw", "effect-filter", "effect-adjust",
        "camera", "album", "close",
        "cannot_more_image_stickers", "cannot_more_text_stickers",
        "alert_clipping_without_state",
    ]

    func testAllEditorLocalizationKeysResolve() {
        for key in keys {
            let value = Bundle.heLocalizedString(key)
            XCTAssertFalse(value.isEmpty, "키가 빈 문자열로 해석됨: \(key)")
            XCTAssertNotEqual(value, key, "로컬라이즈 누락(키 그대로 반환): \(key)")
        }
    }

    func testEachEditToolHasLabel() {
        let tools: [HEImageEditorConfiguration.EditTool] = [.draw, .clip, .imageSticker, .textSticker, .mosaicDraw, .filter, .adjust]
        for tool in tools {
            XCTAssertFalse(tool.label.isEmpty)
            XCTAssertNotEqual(tool.label, "effect-" + tool.name, "툴 라벨 로컬라이즈 누락: \(tool.name)")
        }
    }

    func testWordingsBackedByLocalizationTable() {
        let wordings = HEEditorWordings()
        XCTAssertFalse(wordings.confirm.isEmpty)
        XCTAssertFalse(wordings.rotate.isEmpty)
        XCTAssertFalse(wordings.brightness.isEmpty)
        XCTAssertFalse(wordings.alert.cannotMoreImageStickers.isEmpty)
        XCTAssertFalse(wordings.alert.clippingWithoutState.isEmpty)
    }
}

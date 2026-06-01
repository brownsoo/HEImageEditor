//
//  EditorConfigurationTests.swift
//  HEImageEditorTests
//
//  정적 검사: HEImageEditorConfiguration / UIConfiguration 기본값, 빈값 폴백,
//  체이닝 API, enum 매핑 및 색감 계산식.
//

import XCTest
import UIKit
@testable import HEImageEditor

// 전역 싱글톤 설정을 변경하므로 @MainActor 로 직렬화하여 병렬 실행 간섭을 막는다.
@MainActor
final class EditorConfigurationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        HEImageEditorConfiguration.resetConfiguration()
        HEImageEditorUIConfiguration.resetConfiguration()
    }

    override func tearDown() {
        HEImageEditorConfiguration.resetConfiguration()
        HEImageEditorUIConfiguration.resetConfiguration()
        super.tearDown()
    }

    // MARK: - 기본값

    func testEditorConfigurationDefaults() {
        let config = HEImageEditorConfiguration.default()
        XCTAssertEqual(config.maxImageStickersCount, 50)
        XCTAssertEqual(config.maxTextStickersCount, 50)
        XCTAssertEqual(config.maxTextLength, 60)
        XCTAssertFalse(config.allowClipWithoutKeepingState)
        XCTAssertEqual(config.imageStickerTrayHeight, 156)
        XCTAssertTrue(config.actionDoneEditorWhenImageStickerEditingConfirm)
        XCTAssertTrue(config.actionManagerAllowToStore)
        XCTAssertEqual(config.aiStickerScale, 2.4)
        XCTAssertTrue(config.textStickerCanLineBreak)
        XCTAssertEqual(config.textStickerMaximumLines, 4)
        XCTAssertEqual(config.textStickerMaximumCharactersPerLine, 15)
    }

    func testDefaultToolsContainAllSeven() {
        let tools = HEImageEditorConfiguration.default().tools
        XCTAssertEqual(Set(tools), Set([.draw, .clip, .imageSticker, .textSticker, .mosaicDraw, .filter, .adjust]))
    }

    func testEmptyToolsFallback() {
        let config = HEImageEditorConfiguration.default()
        config.tools = []
        XCTAssertEqual(config.tools, [.textSticker, .imageSticker, .clip])
    }

    func testDefaultClipRatios() {
        let ratios = HEImageEditorConfiguration.default().clipRatios
        XCTAssertEqual(ratios.map(\.whRatio), [HEImageClipRatio.origin, .custom, .wh1x1].map(\.whRatio))
    }

    func testEmptyClipRatiosFallback() {
        let config = HEImageEditorConfiguration.default()
        config.clipRatios = []
        XCTAssertEqual(config.clipRatios.count, 1)
        XCTAssertEqual(config.clipRatios.first?.whRatio, HEImageClipRatio.custom.whRatio)
    }

    func testEmptyDrawColorsFallback() {
        let config = HEImageEditorConfiguration.default()
        config.drawColors = []
        XCTAssertFalse(config.drawColors.isEmpty)
    }

    func testDefaultFiltersEqualsAll() {
        XCTAssertEqual(HEImageEditorConfiguration.default().filters.count, HEFilter.all.count)
    }

    func testDefaultAdjustTools() {
        XCTAssertEqual(HEImageEditorConfiguration.default().adjustTools, [.brightness, .contrast, .saturation])
    }

    // MARK: - 체이닝 API

    func testChainingReturnsSameInstanceAndAppliesValues() {
        let config = HEImageEditorConfiguration.default()
        let returned = config
            .editImageTools([.clip])
            .clipRatios([.wh1x1])
            .filters([.normal])

        XCTAssertTrue(returned === config)
        XCTAssertEqual(config.tools, [.clip])
        XCTAssertEqual(config.clipRatios.count, 1)
        XCTAssertEqual(config.filters.count, 1)
    }

    func testResetConfigurationRestoresDefaults() {
        let config = HEImageEditorConfiguration.default()
        config.maxTextLength = 5
        HEImageEditorConfiguration.resetConfiguration()
        XCTAssertEqual(HEImageEditorConfiguration.default().maxTextLength, 60)
    }

    // MARK: - enum 매핑

    func testEditToolNameMapping() {
        XCTAssertEqual(HEImageEditorConfiguration.EditTool.draw.name, "draw")
        XCTAssertEqual(HEImageEditorConfiguration.EditTool.clip.name, "clip")
        XCTAssertEqual(HEImageEditorConfiguration.EditTool.imageSticker.name, "imageSticker")
        XCTAssertEqual(HEImageEditorConfiguration.EditTool.adjust.name, "adjust")
    }

    func testAdjustToolKeyMapping() {
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.brightness.key, kCIInputBrightnessKey)
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.contrast.key, kCIInputContrastKey)
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.saturation.key, kCIInputSaturationKey)
    }

    // MARK: - 색감 계산식 (filterValue)

    func testBrightnessFilterValueDividesByThree() {
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.brightness.filterValue(0), 0, accuracy: 0.0001)
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.brightness.filterValue(0.99), 0.33, accuracy: 0.0001)
    }

    func testContrastFilterValueRange() {
        // 기본값 1, 음수는 0.5~1, 양수는 1~2.5
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.contrast.filterValue(0), 1, accuracy: 0.0001)
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.contrast.filterValue(1), 2.5, accuracy: 0.0001)
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.contrast.filterValue(-1), 0.5, accuracy: 0.0001)
    }

    func testSaturationFilterValueOffsetByOne() {
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.saturation.filterValue(0), 1, accuracy: 0.0001)
        XCTAssertEqual(HEImageEditorConfiguration.AdjustTool.saturation.filterValue(1), 2, accuracy: 0.0001)
    }

    // MARK: - 회귀 가드 (이전에 수정한 프로덕션 버그)

    func testImpactFeedbackStyleSetterRespectsNewValue() {
        // 이전 버그: setter 가 newValue 를 무시하고 항상 .medium 으로 강제했음.
        let config = HEImageEditorConfiguration.default()
        config.impactFeedbackStyle = .heavy
        XCTAssertEqual(config.impactFeedbackStyle, .heavy)
        config.impactFeedbackStyle = .light
        XCTAssertEqual(config.impactFeedbackStyle, .light)
    }

    func testTextStickerFillColorsAreWithinRange() {
        // 이전 버그: defaultTextFillColors 에 범위 초과값 rgba(524, 184, 0) 존재 → 클램핑됨.
        for color in HEImageEditorConfiguration.default().textStickerBackgroundColors {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            for component in [r, g, b, a] {
                XCTAssertTrue((0...1).contains(component), "색상 컴포넌트가 범위를 벗어남: \(component)")
            }
        }
    }

    // MARK: - UI Configuration

    func testUIConfigurationDefaults() {
        let ui = HEImageEditorUIConfiguration.default()
        XCTAssertEqual(ui.adjustSliderType, .vertical)
        XCTAssertEqual(ui.adjustSliderNormalColor, .white)
        XCTAssertEqual(ui.editDoneBtnTitleColor, .white)
    }
}

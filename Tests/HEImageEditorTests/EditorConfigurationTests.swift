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

    // MARK: - UI Configuration

    func testUIConfigurationDefaults() {
        let ui = HEImageEditorUIConfiguration.default()
        XCTAssertEqual(ui.adjustSliderType, .vertical)
        XCTAssertEqual(ui.adjustSliderNormalColor, .white)
        XCTAssertEqual(ui.editDoneBtnTitleColor, .white)
    }
}

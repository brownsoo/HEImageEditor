//
//  EditorTypeTests.swift
//  HEImageEditorTests
//
//  정적 검사: Type 폴더의 값/모델 로직(클립 비율, 필터, 색감, 편집상태, 스티커).
//

import XCTest
import UIKit
@testable import HEImageEditor

final class EditorTypeTests: XCTestCase {

    // MARK: - HEImageClipRatio

    func testClipRatioValues() {
        XCTAssertEqual(HEImageClipRatio.wh1x1.whRatio, 1)
        XCTAssertEqual(HEImageClipRatio.wh3x4.whRatio, 3.0 / 4.0)
        XCTAssertEqual(HEImageClipRatio.wh16x9.whRatio, 16.0 / 9.0)
        XCTAssertEqual(HEImageClipRatio.custom.whRatio, 0)
    }

    func testCircleRatioForcesWhRatioToOne() {
        XCTAssertTrue(HEImageClipRatio.circle.isCircle)
        XCTAssertEqual(HEImageClipRatio.circle.whRatio, 1)
        // isCircle 이면 생성 시 whRatio 가 강제로 1 이 된다
        let forced = HEImageClipRatio(title: "x", whRatio: 0.5, iconName: "i", isCircle: true)
        XCTAssertEqual(forced.whRatio, 1)
    }

    func testClipRatioAllContainsNineEntries() {
        XCTAssertEqual(HEImageClipRatio.all.count, 9)
    }

    func testClipRatioCloneIsEqualButDistinct() {
        let origin = HEImageClipRatio.wh3x2
        let copy = origin.clone()
        XCTAssertFalse(origin === copy)
        XCTAssertEqual(origin.whRatio, copy.whRatio)
        XCTAssertEqual(origin.title, copy.title)
        XCTAssertEqual(origin.isCircle, copy.isCircle)
    }

    // MARK: - HEFilter

    func testFilterAllContainsSixteenEntries() {
        XCTAssertEqual(HEFilter.all.count, 16)
    }

    func testNormalFilterHasNoApplier() {
        XCTAssertNil(HEFilter.normal.applier)
        XCTAssertEqual(HEFilter.normal.name, "Normal")
    }

    func testFilterTypeCoreImageNames() {
        XCTAssertEqual(HEFilterType.normal.coreImageFilterName, "")
        XCTAssertEqual(HEFilterType.sepia.coreImageFilterName, "CISepiaTone")
        XCTAssertEqual(HEFilterType.noir.coreImageFilterName, "CIPhotoEffectNoir")
        XCTAssertEqual(HEFilterType.chrome.coreImageFilterName, "CIPhotoEffectChrome")
    }

    // MARK: - HEAdjustStatus

    func testAdjustStatusDefaultsAreZero() {
        let status = HEAdjustStatus()
        XCTAssertEqual(status.brightness, 0)
        XCTAssertEqual(status.contrast, 0)
        XCTAssertEqual(status.saturation, 0)
        XCTAssertTrue(status.allValueIsZero)
    }

    func testAdjustStatusNonZeroDetected() {
        XCTAssertFalse(HEAdjustStatus(brightness: 0.1).allValueIsZero)
    }

    // MARK: - HEClipStatus

    func testClipStatusRotationFromAngle() {
        XCTAssertEqual(HEClipStatus(editRect: .zero, angle: 180).rotation, .pi, accuracy: 0.0001)
        XCTAssertEqual(HEClipStatus(editRect: .zero, angle: 90).rotation, .pi / 2, accuracy: 0.0001)
        XCTAssertEqual(HEClipStatus(editRect: .zero, angle: 0).rotation, 0, accuracy: 0.0001)
    }

    func testClipStatusCloneCopiesRatioDistinctly() {
        let origin = HEClipStatus(editRect: CGRect(x: 1, y: 2, width: 3, height: 4),
                                  angle: 45,
                                  ratio: .wh1x1)
        let copy = origin.clone()
        XCTAssertEqual(copy.editRect, origin.editRect)
        XCTAssertEqual(copy.angle, origin.angle)
        XCTAssertFalse(copy.ratio === origin.ratio) // 깊은 복사
        XCTAssertEqual(copy.ratio?.whRatio, origin.ratio?.whRatio)
    }

    // MARK: - HEEditState

    func testEditStateDefaults() {
        let state = HEEditState()
        XCTAssertTrue(state.drawPaths.isEmpty)
        XCTAssertTrue(state.mosaicPaths.isEmpty)
        XCTAssertNil(state.clipStatus)
        XCTAssertNil(state.selectFilter)
        XCTAssertTrue(state.stickers.isEmpty)
        XCTAssertTrue(state.actions.isEmpty)
        XCTAssertFalse(state.fattened)
        XCTAssertTrue(state.adjustStatus.allValueIsZero)
    }

    func testEditStateCloneIsDistinctInstance() {
        let state = HEEditState(clipStatus: HEClipStatus(editRect: .zero, angle: 30),
                                selectFilter: .sepia,
                                fattened: true)
        let copy = state.clone()
        XCTAssertFalse(state === copy)
        XCTAssertEqual(copy.fattened, state.fattened)
        XCTAssertEqual(copy.clipStatus?.angle, 30)
        XCTAssertEqual(copy.selectFilter?.name, "Sepia")
    }

    // MARK: - HEImageSticker

    func testImageStickerDefaultRawSize() {
        XCTAssertEqual(HEImageSticker.defaultImageRawSize, CGSize(width: 1024, height: 1024))
    }

    func testImageStickerSpecialKinds() {
        let mosaic = HEImageSticker(id: "1", kind: .mosaic) { UIImage() }
        let faceAI = HEImageSticker(id: "2", kind: .faceAI) { UIImage() }
        let normal = HEImageSticker(id: "3", kind: .default) { UIImage() }
        XCTAssertTrue(mosaic.isSpecialSticker)
        XCTAssertTrue(faceAI.isSpecialSticker)
        XCTAssertFalse(normal.isSpecialSticker)
    }

    func testImageStickerKindRawValues() {
        XCTAssertEqual(HEImageSticker.Kind.mosaic.rawValue, "mosaic")
        XCTAssertEqual(HEImageSticker.Kind.faceAI.rawValue, "faceAI")
        XCTAssertEqual(HEImageSticker.Kind.default.rawValue, "default")
    }

    // MARK: - HEStickerEffect

    func testImageStickerEffectIsNotTextSticker() {
        let effect = HEImageStickerEffect(id: "i",
                                          kind: .default,
                                          image: UIImage(),
                                          originScale: 1, originAngle: 0,
                                          originFrame: .zero,
                                          gesScale: 1, gesRotation: 0,
                                          totalTranslationPoint: .zero,
                                          visibleFrame: .zero)
        XCTAssertFalse(effect.isTextSticker)
    }

    func testTextStickerEffectIsTextSticker() {
        let effect = HETextStickerEffect(id: "t",
                                         text: "hi",
                                         textColor: .white,
                                         fillColor: .clear,
                                         font: nil,
                                         image: UIImage(),
                                         originScale: 1, originAngle: 0,
                                         originFrame: .zero,
                                         gesScale: 1, gesRotation: 0,
                                         totalTranslationPoint: .zero,
                                         visibleFrame: .zero)
        XCTAssertTrue(effect.isTextSticker)
        XCTAssertEqual(effect.text, "hi")
    }
}

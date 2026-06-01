//
//  EditorUtilityTests.swift
//  HEImageEditorTests
//
//  정적 검사: 순수 유틸리티 익스텐션과 HEEditImage 모델 변환.
//

import XCTest
import UIKit
import HECommon
@testable import HEImageEditor

final class EditorUtilityTests: XCTestCase {

    // MARK: - 시간 변환

    func testIntNanoseconds() {
        XCTAssertEqual(2.nanoseconds, 2_000_000_000)
    }

    func testTimeIntervalNanoseconds() {
        XCTAssertEqual((0.5 as TimeInterval).nanoseconds, 500_000_000)
    }

    // MARK: - CGPoint / CGRect

    func testCGPointMinus() {
        let result = CGPoint(x: 10, y: 8).minus(CGPoint(x: 3, y: 2))
        XCTAssertEqual(result, CGPoint(x: 7, y: 6))
    }

    func testCGPointPlus() {
        let result = CGPoint(x: 1, y: 2).plus(CGPoint(x: 4, y: 6))
        XCTAssertEqual(result, CGPoint(x: 5, y: 8))
    }

    func testCGRectCenter() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        XCTAssertEqual(rect.center, CGPoint(x: 50, y: 25))
    }

    // MARK: - HEEditImage

    private func makeHEImage(id: String = "img-1") -> HEImage {
        HEImage(id: id, origin: URL(fileURLWithPath: "/tmp/\(id).jpg"), phAsset: nil)
    }

    func testToEditImageProducesHEEditImage() {
        let edit = makeHEImage().toEditImage()
        XCTAssertNotNil(edit)
        XCTAssertTrue(edit is HEEditImage)
    }

    func testFromHEImageReturnsSameInstanceWhenAlreadyEdit() {
        let edit = HEEditImage(id: "x", origin: URL(fileURLWithPath: "/tmp/x.jpg"), editState: nil, phAsset: nil)
        XCTAssertTrue(HEEditImage.fromHEImage(edit) === edit)
    }

    func testSetEditStateUpdatesStateAndTimestamp() {
        let edit = HEEditImage(id: "x", origin: URL(fileURLWithPath: "/tmp/x.jpg"), editState: nil, phAsset: nil)
        let before = edit.updatedTime
        let state = HEEditState(fattened: true)

        edit.setEditState(state)

        XCTAssertTrue(edit.editState === state)
        XCTAssertGreaterThanOrEqual(edit.updatedTime, before)
    }

    func testResetToOriginClearsEditState() {
        let edit = HEEditImage(id: "x",
                               origin: URL(fileURLWithPath: "/tmp/x.jpg"),
                               editState: HEEditState(fattened: true),
                               phAsset: nil)
        XCTAssertNotNil(edit.editState)

        edit.resetToOrigin()

        XCTAssertNil(edit.editState)
    }
}

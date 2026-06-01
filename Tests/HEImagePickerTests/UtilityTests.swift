//
//  UtilityTests.swift
//  HEImagePickerTests
//
//  정적 검사: 순수 유틸리티 함수/연산자/익스텐션.
//

import XCTest
import AVFoundation
@testable import HEImagePicker

final class UtilityTests: XCTestCase {

    // MARK: - CGFloat &/ (zero-safe divide)

    func testSafeDivideReturnsZeroWhenDividingByZero() {
        XCTAssertEqual(10.0 as CGFloat &/ 0, 0)
    }

    func testSafeDividePerformsNormalDivision() {
        XCTAssertEqual(10.0 as CGFloat &/ 2, 5)
    }

    // MARK: - Array.get(at:)

    func testArrayGetReturnsElementForValidIndex() {
        let array = [10, 20, 30]
        XCTAssertEqual(array.get(at: 1), 20)
    }

    func testArrayGetReturnsNilForOutOfBoundsIndex() {
        let array = [10, 20, 30]
        XCTAssertNil(array.get(at: 3))
        XCTAssertNil(array.get(at: -1))
    }

    func testArrayGetReturnsNilForEmptyArray() {
        let array: [Int] = []
        XCTAssertNil(array.get(at: 0))
    }

    // MARK: - URL.appendingUniquePathComponent

    func testAppendingUniquePathComponentProducesUniquePaths() {
        let base = URL(fileURLWithPath: "/tmp")
        let a = base.appendingUniquePathComponent()
        let b = base.appendingUniquePathComponent()
        XCTAssertNotEqual(a, b)
    }

    func testAppendingUniquePathComponentAddsExtension() {
        let base = URL(fileURLWithPath: "/tmp")
        let url = base.appendingUniquePathComponent(pathExtension: "jpg")
        XCTAssertEqual(url.pathExtension, "jpg")
    }

    // MARK: - CMTime.seconds / displayTime

    func testCMTimeSecondsReturnsValue() {
        let time = CMTime(seconds: 12, preferredTimescale: 600)
        XCTAssertEqual(time.seconds ?? -1, 12, accuracy: 0.001)
    }

    func testCMTimeSecondsReturnsNilForInvalidTime() {
        XCTAssertNil(CMTime.invalid.seconds)
    }

    func testCMTimeDisplayTimeFormatsMinutesAndSeconds() {
        // DateComponentsFormatter 가 zeroFormattingBehavior = .pad 를 사용하므로 "01:15".
        let time = CMTime(seconds: 75, preferredTimescale: 600)
        XCTAssertEqual(time.displayTime, "01:15")
    }

    // MARK: - HEPickerError

    func testPickerErrorDescriptionExposesMessage() {
        let error = HEPickerError.noAuthorization(message: "no auth")
        XCTAssertEqual(error.errorDescription, "no auth")

        let fileError = HEPickerError.fileFailed(message: "file fail", underlyingError: nil)
        XCTAssertEqual(fileError.errorDescription, "file fail")
    }

    // MARK: - FileManager.removeFileIfNecessary

    func testRemoveFileIfNecessaryNoThrowWhenFileMissing() {
        let missing = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingUniquePathComponent(pathExtension: "tmp")
        XCTAssertNoThrow(try FileManager.default.removeFileIfNecessary(at: missing))
    }

    func testRemoveFileIfNecessaryRemovesExistingFile() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingUniquePathComponent(pathExtension: "tmp")
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data("x".utf8)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        try FileManager.default.removeFileIfNecessary(at: url)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - HELibrarySelection 기본값

    func testLibrarySelectionDefaults() {
        let selection = HELibrarySelection(assetIdentifier: "asset-1")
        XCTAssertEqual(selection.assetIdentifier, "asset-1")
        XCTAssertNil(selection.cropRect)
        XCTAssertNil(selection.scrollViewContentOffset)
        XCTAssertNil(selection.scrollViewZoomScale)
        XCTAssertFalse(selection.isJustPreviewing)
    }

    func testLibrarySelectionRetainsProvidedValues() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let selection = HELibrarySelection(assetIdentifier: "asset-2",
                                           cropRect: rect,
                                           isDefaultPreviewing: true)
        XCTAssertEqual(selection.cropRect, rect)
        XCTAssertTrue(selection.isJustPreviewing)
    }
}

//
//  MediaManagerTests.swift
//  HEImagePickerTests
//
//  정적 검사: HELibraryMediaManager 의 순수 로직(상태/계산).
//

import XCTest
import AVFoundation
@testable import HEImagePicker

final class MediaManagerTests: XCTestCase {

    func testHasResultItemsIsFalseWhenFetchResultIsNil() {
        let manager = HELibraryMediaManager()
        XCTAssertFalse(manager.hasResultItems)
    }

    func testGetAssetReturnsNilWhenFetchResultIsNil() {
        let manager = HELibraryMediaManager()
        XCTAssertNil(manager.getAsset(at: 0))
    }

    // MARK: - getMaxVideoDuration

    func testMaxDurationReturnsAssetDurationWhenLimitIsNil() {
        let manager = HELibraryMediaManager()
        let assetDuration = CMTime(seconds: 30, preferredTimescale: 600)
        let result = manager.getMaxVideoDuration(between: nil, andAssetDuration: assetDuration)
        XCTAssertEqual(result, assetDuration)
    }

    func testMaxDurationReturnsAssetDurationWhenAssetIsShorterThanLimit() {
        let manager = HELibraryMediaManager()
        let limit = CMTime(seconds: 60, preferredTimescale: 600)
        let assetDuration = CMTime(seconds: 30, preferredTimescale: 600)
        let result = manager.getMaxVideoDuration(between: limit, andAssetDuration: assetDuration)
        XCTAssertEqual(result, assetDuration)
    }

    func testMaxDurationReturnsLimitWhenAssetExceedsLimit() {
        let manager = HELibraryMediaManager()
        let limit = CMTime(seconds: 60, preferredTimescale: 600)
        let assetDuration = CMTime(seconds: 120, preferredTimescale: 600)
        let result = manager.getMaxVideoDuration(between: limit, andAssetDuration: assetDuration)
        XCTAssertEqual(result, limit)
    }
}

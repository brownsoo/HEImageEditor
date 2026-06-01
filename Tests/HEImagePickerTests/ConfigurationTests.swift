//
//  ConfigurationTests.swift
//  HEImagePickerTests
//
//  정적 검사: HEImagePickerConfiguration 의 기본값과 구조를 검증한다.
//

import XCTest
import AVFoundation
@testable import HEImagePicker

final class ConfigurationTests: XCTestCase {

    // MARK: - 최상위 기본값

    func testDefaultConfigurationValues() {
        // Arrange / Act
        let config = HEImagePickerConfiguration()

        // Assert
        XCTAssertTrue(config.isDebugLogsEnabled)
        XCTAssertTrue(config.allowZoomablePreview)
        XCTAssertTrue(config.priviewScaleFit)
        XCTAssertTrue(config.allowPickWithoutSelection)
        XCTAssertTrue(config.useEditPhoto)
        XCTAssertFalse(config.scrollTopIfSelectedWhenPreviewIsHidden)
        XCTAssertTrue(config.onlySquareImagesFromCamera)
        XCTAssertTrue(config.showsVideoTrimmer)
        XCTAssertTrue(config.shouldSaveNewPicturesToAlbum)
        XCTAssertFalse(config.shouldSelectSingleType)
        XCTAssertFalse(config.hidesCancelButton)
        XCTAssertTrue(config.hidesStatusBar)
        XCTAssertFalse(config.hidesBottomBar)
    }

    func testDefaultPickerSourcesContainAllSources() {
        let config = HEImagePickerConfiguration()
        XCTAssertEqual(config.pickerSources, [.libraryPick, .photoCapture, .videoCapture])
    }

    func testDefaultTargetImageSizeIsCappedTo1280() {
        let config = HEImagePickerConfiguration()
        guard case let .cappedTo(size) = config.targetImageSize else {
            return XCTFail("기본 targetImageSize 는 .cappedTo 여야 한다")
        }
        XCTAssertEqual(size, 1280)
    }

    // MARK: - Library 기본값

    func testLibraryDefaults() {
        let library = HEImagePickerConfiguration.Library()

        XCTAssertFalse(library.onlySquare)
        XCTAssertFalse(library.usingClop)
        XCTAssertTrue(library.isCropSquareByDefault)
        XCTAssertEqual(library.mediaType, .photo)
        XCTAssertFalse(library.defaultMultipleSelection)
        XCTAssertFalse(library.preSelectItemOnMultipleSelection)
        XCTAssertEqual(library.maxNumberOfItems, 1)
        XCTAssertEqual(library.minNumberOfItems, 1)
        XCTAssertEqual(library.numberOfItemsInRow, 4)
        XCTAssertEqual(library.spacingBetweenItems, 1.5)
        XCTAssertFalse(library.skipSelectionsGallery)
        XCTAssertNil(library.preselectedItems)
        XCTAssertTrue(library.addToSelectionBySigleTouch)
    }

    func testLibraryMaxItemsCannotBeBelowMinByDefault() {
        // min/max 의 기본 불변식: max >= min
        let library = HEImagePickerConfiguration.Library()
        XCTAssertGreaterThanOrEqual(library.maxNumberOfItems, library.minNumberOfItems)
    }

    // MARK: - Video 기본값

    func testVideoDefaults() {
        let video = HEImagePickerConfiguration.HEConfigVideo()

        XCTAssertFalse(video.disableCompressing)
        XCTAssertEqual(video.compression, AVAssetExportPresetHighestQuality)
        XCTAssertEqual(video.fileType, .mp4)
        XCTAssertEqual(video.recordingTimeLimit, 600.0)
        XCTAssertNil(video.recordingSizeLimit)
        XCTAssertEqual(video.minFreeDiskSpaceLimit, 1024 * 1024)
        XCTAssertEqual(video.libraryTimeLimit, 60.0)
        XCTAssertEqual(video.minimumTimeLimit, 0.1)
        XCTAssertFalse(video.limitVideoTimeLImit)
        XCTAssertEqual(video.maxVideoFileSize, 500 * 1024 * 1024)
        XCTAssertEqual(video.trimmerMaxDuration, 60.0)
        XCTAssertEqual(video.trimmerMinDuration, 3.0)
        XCTAssertFalse(video.automaticTrimToTrimmerMaxDuration)
    }

    func testVideoTrimmerDurationInvariant() {
        // 트리머 최대 길이는 최소 길이보다 길어야 한다
        let video = HEImagePickerConfiguration.HEConfigVideo()
        XCTAssertGreaterThan(video.trimmerMaxDuration, video.trimmerMinDuration)
    }

    func testVideoFileTypeExtensionIsResolvable() {
        let video = HEImagePickerConfiguration.HEConfigVideo()
        let ext = video.fileType.fileExtension
        XCTAssertEqual(ext, "mp4")
    }

    // MARK: - screenWidth

    @MainActor
    func testScreenWidthIsPositive() {
        XCTAssertGreaterThan(HEImagePickerConfiguration.screenWidth, 0)
    }
}

//
//  LocalizationTests.swift
//  HEImagePickerTests
//
//  정적 검사: 리소스 번들/로컬라이즈 키가 모두 해석되는지(누락 없음) 검증한다.
//  로케일(ko/en) 에 의존하지 않도록, 값이 키 자신으로 반환되지 않는지만 확인한다.
//

import XCTest
@testable import HEImagePicker

final class LocalizationTests: XCTestCase {

    /// HEPickerWordings 에서 참조하는 모든 로컬라이즈 키.
    private let localizationKeys: [String] = [
        "_albums", "_cancel", "_cover", "_crop", "_done", "_filter", "_library",
        "_next", "_ok", "_permissionDeniedPopupCancel", "_permissionDeniedPopupGrantPermission",
        "_permissionDeniedPopupTitle", "_perms_accessing_album", "_perms_limited_album",
        "_perms_accessing_camera", "_perms_limited_camera", "_photo", "_processing",
        "_save", "_trim", "_video", "_videoDurationTitle", "_videoTooLong", "_videoTooShort",
        "_warningItemsLimit", "_attach", "_editPhoto", "_all", "_allPhotos", "_allVideos",
        "_confirm", "_close", "_noSupportCameraDevice", "_noPhotoLibraryAuthor",
        "_errorOnSaveImageInLibrary", "_errorOnSaveVideoInLibrary", "_noSelectionToEdit",
        "_cannotFindMediaFile", "_videoTooHeavy", "_edited", "_library_changed_alert",
        "_photos_empty_messge", "_only_video_selectable", "_only_image_selectable",
    ]

    func testAllLocalizationKeysResolve() {
        for key in localizationKeys {
            let value = pickerLocalized(key)
            XCTAssertFalse(value.isEmpty, "키가 빈 문자열로 해석됨: \(key)")
            XCTAssertNotEqual(value, key, "로컬라이즈 누락(키 그대로 반환): \(key)")
        }
    }

    func testStringFormatSpecifiersPreserved() {
        // %d : 최대 선택 개수 경고
        XCTAssertTrue(pickerLocalized("_warningItemsLimit").contains("%d"))
        // %@ : 비디오 길이/용량 경고
        XCTAssertTrue(pickerLocalized("_videoTooLong").contains("%@"))
        XCTAssertTrue(pickerLocalized("_videoTooShort").contains("%@"))
        XCTAssertTrue(pickerLocalized("_videoTooHeavy").contains("%@"))
    }

    func testWordingsAreBackedByLocalizationTable() {
        let wordings = HEPickerWordings()
        XCTAssertFalse(wordings.confirm.isEmpty)
        XCTAssertFalse(wordings.attach.isEmpty)
        XCTAssertFalse(wordings.cancel.isEmpty)
        XCTAssertFalse(wordings.libraryPermissionPopup.title.isEmpty)
        XCTAssertFalse(wordings.cameraPermissionPopup.messageAccess.isEmpty)
        XCTAssertFalse(wordings.videoDurationPopup.tooLongMessage.isEmpty)
    }

    func testWarningMaxItemsLimitFormatsWithCount() {
        let formatted = String(format: HEPickerWordings().warningMaxItemsLimit, arguments: [5])
        XCTAssertTrue(formatted.contains("5"))
        XCTAssertFalse(formatted.contains("%d"))
    }
}

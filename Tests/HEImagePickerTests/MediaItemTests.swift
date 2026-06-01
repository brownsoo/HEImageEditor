//
//  MediaItemTests.swift
//  HEImagePickerTests
//
//  정적 검사: HEMediaItem / HEMediaPhoto / HEMediaVideo 모델 로직.
//

import XCTest
import UIKit
@testable import HEImagePicker

final class MediaItemTests: XCTestCase {

    private func makePhoto(id: String?) -> HEMediaPhoto {
        HEMediaPhoto(identifier: id,
                     url: URL(fileURLWithPath: "/tmp/photo.jpg"),
                     thumbnail: nil)
    }

    private func makeVideo(id: String?) -> HEMediaVideo {
        HEMediaVideo(identifier: id,
                     videoURL: URL(fileURLWithPath: "/tmp/video.mp4"),
                     thumbnailTask: nil)
    }

    // MARK: - identifier fallback

    func testPhotoUsesGivenIdentifier() {
        let photo = makePhoto(id: "given-id")
        XCTAssertEqual(photo.identifier, "given-id")
    }

    func testPhotoGeneratesUUIDWhenIdentifierIsNil() {
        let photo = makePhoto(id: nil)
        XCTAssertFalse(photo.identifier.isEmpty)
        XCTAssertNotNil(UUID(uuidString: photo.identifier))
    }

    func testVideoUsesGivenIdentifier() {
        let video = makeVideo(id: "video-id")
        XCTAssertEqual(video.identifier, "video-id")
    }

    func testVideoGeneratesUUIDWhenIdentifierIsNil() {
        let video = makeVideo(id: nil)
        XCTAssertNotNil(UUID(uuidString: video.identifier))
    }

    // MARK: - HEMediaItem 접근자

    func testMediaItemPhotoExposesIdentifierAndNilAsset() {
        let item = HEMediaItem.photo(p: makePhoto(id: "p1"))
        XCTAssertEqual(item.identifier, "p1")
        XCTAssertNil(item.phAsset)
    }

    func testMediaItemVideoExposesIdentifier() {
        let item = HEMediaItem.video(v: makeVideo(id: "v1"))
        XCTAssertEqual(item.identifier, "v1")
    }

    // MARK: - Array<HEMediaItem> 편의 접근자

    func testSinglePhotoReturnsFirstPhoto() {
        let items: [HEMediaItem] = [.photo(p: makePhoto(id: "p1")), .video(v: makeVideo(id: "v1"))]
        XCTAssertEqual(items.singlePhoto?.identifier, "p1")
        XCTAssertNil(items.singleVideo)
    }

    func testSingleVideoReturnsFirstVideo() {
        let items: [HEMediaItem] = [.video(v: makeVideo(id: "v1")), .photo(p: makePhoto(id: "p1"))]
        XCTAssertEqual(items.singleVideo?.identifier, "v1")
        XCTAssertNil(items.singlePhoto)
    }

    func testPhotoItemsFiltersOnlyPhotos() {
        let items: [HEMediaItem] = [
            .photo(p: makePhoto(id: "p1")),
            .video(v: makeVideo(id: "v1")),
            .photo(p: makePhoto(id: "p2")),
        ]
        XCTAssertEqual(items.photoItems.map(\.identifier), ["p1", "p2"])
    }

    func testVideoItemsFiltersOnlyVideos() {
        let items: [HEMediaItem] = [
            .photo(p: makePhoto(id: "p1")),
            .video(v: makeVideo(id: "v1")),
            .video(v: makeVideo(id: "v2")),
        ]
        XCTAssertEqual(items.videoItems.map(\.identifier), ["v1", "v2"])
    }

    func testEmptyArrayHelpersReturnNilOrEmpty() {
        let items: [HEMediaItem] = []
        XCTAssertNil(items.singlePhoto)
        XCTAssertNil(items.singleVideo)
        XCTAssertTrue(items.photoItems.isEmpty)
        XCTAssertTrue(items.videoItems.isEmpty)
    }
}

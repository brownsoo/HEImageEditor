//
//  HEImageSticker.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/24/24.
//

import Foundation
import UIKit

/// 이미지 스티커 소스
public class HEImageSticker: NSObject {
    
    public enum Kind: String {
        case mosaic
        case faceAI
        case `default`
    }
    
    /// 기본 이미지 스티커 사이즈와 동일하게 만들기 위해
    /// 편집 화면에 붙는 스티커 이미지 크기를 조절한다.
    public static let defaultImageRawSize = CGSize(width: 1024, height: 1024)
    
    public static var faceAiIcon: HEImageSticker = {
        HEImageSticker(id: UUID().uuidString, kind: .faceAI) {
            UIImage.he.getImage("editStickerFaceAi") ?? UIImage(systemName: "faceid")!
        }
    }()
    
    public static var mosaicIcon: HEImageSticker = {
        HEImageSticker(id: UUID().uuidString, kind: .mosaic) {
            UIImage.he.getImage("editStickerMosaic") ?? UIImage(systemName: "mosaic")!
        }
    }()
    
    public var isSpecialSticker: Bool { self.kind == .faceAI || self.kind == .mosaic }
    
    public let id: String
    public let kind: Kind
    public var imageLoader: (() async -> UIImage)
    public var cachedImage: UIImage?
    
    public init(id: String, kind: Kind = .default, imageLoader: @escaping () async -> UIImage) {
        self.id = id
        self.kind = kind
        self.imageLoader = imageLoader
    }
}

/// 이미지 스티커 뷰 대상
@objc public protocol HEImageStickerTray {
    weak var dataSource: HEImageStickerTrayViewDataSource? { get set }
    var selectImageStickerBlock: ((HEImageSticker) -> Void)? { get set }
    /// 숨겨질 때 호출
    ///
    /// - instantly 여부 전달 
    var hideBlock: ((Bool) -> Void)? { get set }
    var hasMosaicSticker: Bool { get }
    
    func show(in parent: UIView, frame: CGRect)
    func hide(instantly: Bool)
    func randomStickerOnFace(inSection section: Int) -> HEImageSticker?
}

public extension HEImageStickerTray {
    func hide() {
        hide(instantly: false)
    }
}

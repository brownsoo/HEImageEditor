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
    // public private(set) var image: UIImage?
    public let kind: Kind
    public var imageLoader: (() async -> UIImage)
    
//    public init(id: String, kind: Kind = .default, image: UIImage) {
//        self.id = id
//        self.image = image // TODO: lazy loading
//        self.kind = kind
//    }
    
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
    var hideBlock: (() -> Void)? { get set }
    var hasMosaicSticker: Bool { get }
    
    func show(in parent: UIView, frame: CGRect)
    func hide()
    func randomSticker(inSection section: Int) -> HEImageSticker?
}

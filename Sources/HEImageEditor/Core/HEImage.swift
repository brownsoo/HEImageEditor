//
//  HEImage.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit

//public protocol HEImage: Codable {
//    /// 원본 이미지, 효과 정보를 가진 데이터
//    
//    var id: String { get }
//    var origin: URL { get }
//    /// 중간 정리된 파일
//    var fatten: URL? { get }
//    var thumbnailFile: URL? { get }
//    
//    var effects: [HEEffect] { get set }
//    
//    func makeUIImage() -> UIImage
//    func applyEffect(_ effect: HEEffect)
//}

public struct HEImage: Codable {
    
    enum CodingKeys: String, CodingKey {
        case origin
        case effects
        case frame
    }
    
    public private(set) var id: String
    public private(set) var origin: URL
    public var frame: CGRect
    
    public var fatten: String? {
        nil
    }
    
    public var thumbnailFile: String? {
        nil
    }
    
    public var effects: [HEEffect]
    
    public init(origin: URL, effects: [HEEffect]) {
        self.id = origin.absoluteString
        self.origin = origin
        self.effects = effects
        self.frame = .zero
    }
    
    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.origin = try container.decode(URL.self, forKey: .origin)
//        var array = NSMutableArray()
//        for effect in effects {
//            array.add(effect)
//        }
        fatalError("init(coder:) has not been implemented")
    }
    
    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.origin, forKey: .origin)
//        var array = NSMutableArray()
//        for effect in effects {
//            array.add(effect)
//        }
//        try container.encode(array, forKey: .effects)
        fatalError("init(coder:) has not been implemented")
    }

    public func makeUIImage() -> UIImage {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func applyEffect(_ effect: HEEffect) {
        fatalError("init(coder:) has not been implemented")
    }
}


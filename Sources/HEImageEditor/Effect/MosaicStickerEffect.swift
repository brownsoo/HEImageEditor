//
//  MosaicStickerEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public class MosaicStickerEffect: BlurStickerEffect {
    public var mosaicSize: CGFloat
    
     init(mosaicSize: CGFloat = 20, blurRadius: CGFloat = 10, blurType: Int = 0) {
        self.mosaicSize = mosaicSize
        super.init(blurRadius: blurRadius, blurType: blurType)
    }
    
    enum CodingKeys: CodingKey {
        case mosaicSize
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.mosaicSize = try container.decode(CGFloat.self, forKey: .mosaicSize)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.mosaicSize, forKey: .mosaicSize)
    }
}

//
//  HEImageClipRatio.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/20/24.
//

import Foundation

public class HEImageClipRatio: NSObject {
    @objc public var title: String
    @objc public var whRatio: CGFloat
    @objc public let iconName: String
    @objc public let isCircle: Bool
    
    @objc
    public init(title: String, whRatio: CGFloat, iconName: String, isCircle: Bool = false) {
        self.title = title
        self.whRatio = isCircle ? 1 : whRatio
        self.iconName = iconName
        self.isCircle = isCircle
        super.init()
    }
    
    func clone() -> HEImageClipRatio {
        HEImageClipRatio(title: self.title, whRatio: self.whRatio, iconName: self.iconName, isCircle: self.isCircle)
    }
}

extension HEImageClipRatio {
    static func == (lhs: HEImageClipRatio, rhs: HEImageClipRatio) -> Bool {
        return lhs.whRatio == rhs.whRatio
    }
}

public extension HEImageClipRatio {
    @objc static let all: [HEImageClipRatio] = [.custom, .circle, .wh1x1, .wh3x4, .wh4x3, .wh2x3, .wh3x2, .wh9x16, .wh16x9]
    
    @objc static let origin = HEImageClipRatio(title: "original",
                                               whRatio: -1, iconName: "icEditThumOriginal") // whRatio: HEClipActionToolView 에서 조정됨.
    @objc static let custom = HEImageClipRatio(title: "custom ratio", 
                                               whRatio: 0, iconName: "icEditThumFree")
    @objc static let circle = HEImageClipRatio(title: "circle ratio", 
                                               whRatio: 1, iconName: "icEditThumSquare", isCircle: true)
    
    @objc static let wh1x1 = HEImageClipRatio(title: "1 : 1", whRatio: 1, iconName: "icEditThumSquare")
    @objc static let wh3x4 = HEImageClipRatio(title: "3 : 4", whRatio: 3.0 / 4.0, iconName: "icEditThumSquare")
    @objc static let wh4x3 = HEImageClipRatio(title: "4 : 3", whRatio: 4.0 / 3.0, iconName: "icEditThumSquare")
    @objc static let wh2x3 = HEImageClipRatio(title: "2 : 3", whRatio: 2.0 / 3.0, iconName: "icEditThumSquare")
    @objc static let wh3x2 = HEImageClipRatio(title: "3 : 2", whRatio: 3.0 / 2.0, iconName: "icEditThumSquare")
    @objc static let wh9x16 = HEImageClipRatio(title: "9 : 16", whRatio: 9.0 / 16.0, iconName: "icEditThumSquare")
    @objc static let wh16x9 = HEImageClipRatio(title: "16 : 9", whRatio: 16.0 / 9.0, iconName: "icEditThumSquare")
}

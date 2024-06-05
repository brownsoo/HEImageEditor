//
//  HEColor.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import CoreGraphics
import UIKit

public struct HEColor: Codable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat
    
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public init(color: UIColor) {
        self.red = 0
        self.green = 0
        self.blue = 0
        self.alpha = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
    
    public init(white: CGFloat, alpha: CGFloat = 1) {
        self.red = white
        self.green = white
        self.blue = white
        self.alpha = alpha
    }
}

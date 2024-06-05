//
//  HEInteraction.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public protocol HEResizable {
    var resized: CGFloat { get set }
}

public protocol HETranslatable {
    func tranlate(x: CGFloat, y: CGFloat)
}
public protocol HERotatable {
    /// radians
    var rotated: CGFloat { get set }
}

public protocol HECroppable {
    func crop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)
}

public protocol HETransfomable: HEResizable, HETranslatable, HERotatable {
}


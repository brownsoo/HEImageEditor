//
//  Foundation+.swift
//  HEImageEditor
//
//  Created by hyonsoo on 6/13/24.
//

import Foundation
import Combine


extension Int {
    var nanoseconds: UInt64 {
        return UInt64(self * 1_000_000_000)
    }
}

extension TimeInterval {
    var nanoseconds: UInt64 {
        return UInt64(self * 1_000_000_000)
    }
}

// Combine Cancellable
extension Task : @retroactive Cancellable {}

extension CGPoint {
    func minus(_ dest: CGPoint) -> CGPoint {
        CGPoint(x: self.x - dest.x,
                y: self.y - dest.y)
    }
    
    func plus(_ dest: CGPoint) -> CGPoint {
        CGPoint(x: self.x + dest.x,
                y: self.y + dest.y)
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: self.midX, y: self.midY)
    }
}

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
extension Task : Cancellable {}

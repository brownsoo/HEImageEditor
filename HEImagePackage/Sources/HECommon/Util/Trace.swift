//
//  Trace.swift
//  HECommon
//
//  Created by 브라운수 on 7/8/24.
//

import Foundation

let lg = HELogger(category: "HE", tag: "*common*")

extension Int64 {
    func logFileSize() {
#if DEBUG
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [ByteCountFormatter.Units.useKB]
        bcf.countStyle = ByteCountFormatter.CountStyle.memory
        let bytesString = bcf.string(fromByteCount: self)
        lg.trace(bytesString)
#endif
    }
}

extension Int {
    func logFileSize() {
        Int64(self).logFileSize()
    }
}

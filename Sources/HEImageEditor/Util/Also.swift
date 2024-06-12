//
//  Also.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/11/24.
//

import Foundation

public protocol Also {}

public extension Also {
    @discardableResult
    func also(perform thisFn: (Self)->Void) -> Self {
        thisFn(self)
        return self
    }
}

extension NSObject: Also {}

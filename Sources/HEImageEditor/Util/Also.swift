//
//  Also.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/11/24.
//

import Foundation

protocol Also {}

extension Also {
    @discardableResult
    func also(perform thisFn: (Self)->Void) -> Self {
        thisFn(self)
        return self
    }
}

extension NSObject: Also {}

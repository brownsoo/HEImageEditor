//
//  Foundation+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/3/24.
//

import Foundation
import Combine

// Combine Cancellable
extension Task : Cancellable {}

extension Array {
    func get(at index: Int) -> Element? {
        guard index >= 0, index < self.count else {
            return nil
        }
        return self[index]
    }
}

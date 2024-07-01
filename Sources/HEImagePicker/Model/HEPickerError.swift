//
//  HEPickerError.swift
//  HEImagePicker
//
//  Created by hyonsoo on 7/2/24.
//

import Foundation

enum HEPickerError: Error, LocalizedError {
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .custom(let message):
            return message
        }
    }
}

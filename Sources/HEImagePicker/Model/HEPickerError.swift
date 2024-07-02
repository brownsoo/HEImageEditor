//
//  HEPickerError.swift
//  HEImagePicker
//
//  Created by hyonsoo on 7/2/24.
//

import Foundation

enum HEPickerError: Error, LocalizedError {
    case fileFailed(message: String, underlyingError: Error?)
    case videoTrimFailed(message: String, underlyingError: Error?)
    case custom(message: String, underlyingError: Error?)

    var errorDescription: String? {
        switch self {
        case .fileFailed(let message, _):
            return message
        case .videoTrimFailed(let message, _):
            return message
        case .custom(let message, _):
            return message
        }
    }
}

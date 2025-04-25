//
//  URL+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation

extension URL {
    /// Adds a unique path to url
    func appendingUniquePathComponent(pathExtension: String? = nil) -> URL {
        var pathComponent = UUID().uuidString
        if let pathExtension = pathExtension {
            pathComponent += ".\(pathExtension)"
        }
        return appendingPathComponent(pathComponent)
    }
}

//
//  File+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation
extension FileManager {
    func removeFileIfNecessary(at url: URL) throws {
        guard fileExists(atPath: url.path) else {
            return
        }
        
        do {
            try removeItem(at: url)
        } catch {
            throw HEPickerError.fileFailed(message: "Couldn't remove existing destination file.", underlyingError: error)
        }
    }
}

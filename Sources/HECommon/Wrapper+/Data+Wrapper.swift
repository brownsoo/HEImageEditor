//
//  Data+Wrapper.swift
//  HECommon
//
//  Created by 브라운수 on 7/8/24.
//

import Foundation
import UIKit

public extension HEWrapper where Base == Data {
    
    func metadataForImageData() -> [String: Any] {
        if let imageSource = CGImageSourceCreateWithData(base as CFData, nil),
           let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil),
           let metaData = imageProperties as? [String: Any] {
            return metaData
        }
        return [:]
    }
}

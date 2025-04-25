//
//  HEImageCache.swift
//  HEImageEditor
//
//  Created by hyonsoo on 6/23/24.
//

import Foundation
import UIKit

public protocol HEImageDataStore {
    
    func addHEImage(_ hei: HEImage, excepting: ((HEImage) -> Bool)?)
    func addHEImages(_ heis: [HEImage], excepting: ((HEImage) -> Bool)?)
    
    func removeHEImage(_ id: String)
    func removeHEImage(_ he: HEImage)
    func clearAll()
    
    func all() -> [HEImage]
    func numberOfImages() -> Int
    func getHEImage(at index: Int) -> HEImage?
    
    func getHEImage(forId id: String) -> HEImage?
    
    func getHEImage(forAssetIdentifier identifier: String) -> HEImage?
    
    @discardableResult
    func replaceHEImage(at index: Int, with item: HEImage) -> Bool
    
    @discardableResult
    func replaceHEImage(_ exist: HEImage, with item: HEImage) -> Bool
    
    func sorts(byIds ids: [String])
}

public extension HEImageDataStore {
    func addHEImage(_ hei: HEImage) {
        self.addHEImage(hei, excepting: nil)
    }
    func addHEImages(_ heis: [HEImage]) {
        self.addHEImages(heis, excepting: nil)
    }
}

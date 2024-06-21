//
//  HEImage.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import Combine
import UIKit

@MainActor
public class HEImage {
    
    public private(set) var id: String
    private(set) var origin: URL?
    private(set) var originImage: UIImage?
    public private(set) var thumbnailURL: URL?
    public private(set) var editImageURL: URL?
    public var editModel: HEEditImageModel?
    private var cancellables = Set<AnyCancellable>()
    
    public init(origin: URL, editModel: HEEditImageModel?) {
        self.id = UUID().uuidString
        self.origin = origin
        self.editModel = editModel
    }
    
    public init(image: UIImage, editModel: HEEditImageModel?) {
        self.id = UUID().uuidString
        self.originImage = image
        self.editModel = editModel
    }
}

extension HEImage {
    
    func originImage() async throws -> UIImage {
        if let originImage {
            return originImage
        } else if let origin {
            let image = try await Task.detached {
                let data = try Data(contentsOf: origin)
                return UIImage(data: data)!
            }.value
            return image
        }
        throw HEError.imageNotFound
    }
    
    func directoryURL() -> URL {
        if #available(iOS 16.0, *) {
            return FileManager.default.temporaryDirectory.appending(path: "he", directoryHint: .isDirectory)
        } else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("he", isDirectory: true)
        }
    }
    
    func storeEditImage(uiImage: UIImage) async throws -> URL? {
        let dir = directoryURL()
        let fileName = self.id + ".png"
        return try await Task.detached {
            guard let data = uiImage.pngData() else {
                throw HEError.generateFileData
            }
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            
            let fileURL: URL
            if #available(iOS 16.0, *) {
                fileURL = dir.appending(path: fileName, directoryHint: .notDirectory)
            } else {
                fileURL = dir.appendingPathComponent(fileName, isDirectory: false)
            }
            
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            return fileURL
        }.value
    }
    
    
}


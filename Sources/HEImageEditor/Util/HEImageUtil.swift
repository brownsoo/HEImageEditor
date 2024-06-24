//
//  ImageUtil.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/24/24.
//

import UIKit
import Foundation
import AVFoundation
import Photos

public struct CannotMakeJpegError: Error {
    public var localizedDescription: String {
        return "Can't make a jpeg"
    }
}

public struct CannotFindImageError: Error {
    public var localizedDescription: String {
        return "Can't find an image"
    }
}

public class HEImageUtil {
    
    private init(){}
    
    public static func checkImageDataAndResize(image: UIImage,
                                        maxFileSize: Double = 5.0 * 1024 * 1024, // 5MB
                                        preferImageResizingSize: CGFloat = 1400, // points
                                        resultHandler: @escaping (Data?) -> Void) {
        DispatchQueue.global().async {
            guard let fileData = image.jpegData(compressionQuality: 0.8) else {
                DispatchQueue.main.async {
                    resultHandler(nil)
                }
                return
            }
            checkImageDataAndResize(imageData: fileData, maxFileSize: maxFileSize, preferImageResizingSize: preferImageResizingSize) { (data) in
                resultHandler(data)
            }
        }
    }
    
    public static func checkImageDataAndResize(imageData: Data,
                                        maxFileSize: Double = 5.0 * 1024 * 1024, // 5MB
                                        preferImageResizingSize: CGFloat = 1400, // points
                                        resultHandler: @escaping (Data) -> Void) {
        var fileData = imageData
        DispatchQueue.global().async {
            #if DEBUG
            var bcf = ByteCountFormatter()
            bcf.allowedUnits = [ByteCountFormatter.Units.useKB]
            bcf.countStyle = ByteCountFormatter.CountStyle.memory
            var bytesString = bcf.string(fromByteCount: Int64(fileData.count))
            debugPrint("ImageUtil.checkImageDataAndResize::파일 크기:" + bytesString)
            #endif
            
            // 이미지인데, 파일 크기가 크면 사이즈 줄이기
            if let image = UIImage(data: fileData),
               (Double(fileData.count) >= maxFileSize || image.size.width * image.size.height > preferImageResizingSize * preferImageResizingSize)
            {
                debugPrint("ImageUtil.checkImageDataAndResize::original image size = \(image.size.width) x \(image.size.height)")
                var newImage: UIImage
                if image.size.width > image.size.height {
                    newImage = image.he.resize(newWidth: preferImageResizingSize)
                } else {
                    newImage = image.he.resize(newHeight: preferImageResizingSize)
                }
                debugPrint("ImageUtil.checkImageDataAndResize::resized image size = \(newImage.size.width) x \(newImage.size.height)")
                if let data = newImage.jpegData(compressionQuality: 0.7) {
                    debugPrint("ImageUtil.checkImageDataAndResize::jpeg image")
                    fileData = data
                }
            }
            
            #if DEBUG
            bcf = ByteCountFormatter()
            bcf.allowedUnits = [ByteCountFormatter.Units.useKB]
            bcf.countStyle = ByteCountFormatter.CountStyle.memory
            bytesString = bcf.string(fromByteCount: Int64(fileData.count))
            debugPrint("ImageUtil.checkImageDataAndResize::수정된 파일 크기:" + bytesString)
            #endif
            DispatchQueue.main.async {
                resultHandler(fileData)
            }
        }
    }
    /// 이미지면 사이즈 줄이기를 시도.
    public static func checkFileSizeAndCache(fileUrl: URL,
                                      maxFileSize: Double = 5.0 * 1024 * 1024, // 5MB
                                      preferImageResizingSize: CGFloat = 1400, // points
                                      resultHandler: @escaping (URL?, Error?) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            do {
                var fileData = try Data(contentsOf: fileUrl)
                
                #if DEBUG
                var bcf = ByteCountFormatter()
                bcf.allowedUnits = [ByteCountFormatter.Units.useKB]
                bcf.countStyle = ByteCountFormatter.CountStyle.memory
                var bytesString = bcf.string(fromByteCount: Int64(fileData.count))
                debugPrint("checkFileSizeAndCache: 파일 크기:" + bytesString)
                #endif
                
                // 이미지인데, 파일 크기가 크면 사이즈 줄이기
                if let image = UIImage(data: fileData),
                   (Double(fileData.count) >= maxFileSize)
                {
                    debugPrint("checkFileSizeAndCache: 원본 size = \(image.size.width) x \(image.size.height)")
                    var newImage: UIImage
                    if image.size.width > image.size.height {
                        newImage = image.he.resize(newWidth: preferImageResizingSize)
                    } else {
                        newImage = image.he.resize(newHeight: preferImageResizingSize)
                    }
                    debugPrint("checkFileSizeAndCache: 변경 size = \(newImage.size.width) x \(newImage.size.height)")
                    if let data = newImage.jpegData(compressionQuality: 0.7) {
                        fileData = data
                    }
                }
                
                #if DEBUG
                bcf = ByteCountFormatter()
                bcf.allowedUnits = [ByteCountFormatter.Units.useKB]
                bcf.countStyle = ByteCountFormatter.CountStyle.memory
                bytesString = bcf.string(fromByteCount: Int64(fileData.count))
                debugPrint("checkFileSizeAndCache: 수정된 파일 크기:" + bytesString)
                #endif
                let manager = FileManager.default
                let cacheDir = manager.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let writeUrl = cacheDir.appendingPathComponent(fileUrl.lastPathComponent)
                debugPrint("checkFileSizeAndCache: 캐시에 쓰기 : \(writeUrl.absoluteString)")
                try fileData.write(to: writeUrl, options: [Data.WritingOptions.fileProtectionMask])
                DispatchQueue.main.async {
                    resultHandler(writeUrl, nil)
                }
            } catch {
                let e = error
                DispatchQueue.main.async {
                    resultHandler(nil, e)
                }
            }
        }
    }
    
    public static func saveTempImageUsingJpeg(_ image: UIImage, name: String, completion: @escaping (URL?, Error?) -> Void) {
        DispatchQueue.global().async {
            let tempDir = FileManager.default.temporaryDirectory
            let writeUrl = tempDir.appendingPathComponent(name)
            debugPrint("write to: \(writeUrl.absoluteString)")
            do {
                if let data = image.jpegData(compressionQuality: 0.7) {
                    try data.write(to: writeUrl, options: [Data.WritingOptions.fileProtectionMask])
                    DispatchQueue.main.async {
                        completion(writeUrl, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, CannotMakeJpegError())
                    }
                }
                
            } catch {
                let e = error
                DispatchQueue.main.async {
                    completion(nil, e)
                }
            }
        }
    }
    
    public static func saveTempImageUsingJpeg(_ data: Data, name: String, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global().async {
            let tempDir = FileManager.default.temporaryDirectory
            let writeUrl = tempDir.appendingPathComponent(name)
            debugPrint("write to: \(writeUrl.absoluteString)")
            do {
                try data.write(to: writeUrl, options: [Data.WritingOptions.fileProtectionMask])
                DispatchQueue.main.async {
                    completion(.success(writeUrl))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

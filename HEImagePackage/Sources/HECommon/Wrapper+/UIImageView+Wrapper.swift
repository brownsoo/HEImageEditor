//
//  UIImageView+Wrapper.swift
//  HECommon
//
//  Created by 브라운수 on 8/13/24.
//

import UIKit
import ImageIO

public extension HEWrapper where Base: UIImageView {
    func loadGif(url: URL, callback: ((Bool) -> Void)? = nil) {
        DispatchQueue.global().async {
            guard let imageData = try? Data(contentsOf: url) else {
                callback?(false)
                return
            }
            loadGif(data: imageData, callback: callback)
        }
    }
    
    func loadGif(data: Data, callback: ((Bool) -> Void)? = nil) {
        loadGif(cfData: data as CFData, callback: callback)
    }
    
    func loadGif(cfData: CFData, callback: ((Bool) -> Void)? = nil) {
        DispatchQueue.global().async {
            guard let source = CGImageSourceCreateWithData(cfData, nil) else {
                callback?(false)
                return
            }
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
            let meta = imageProperties as? [String: Any]
            var delay: Double = 0.1
            if let gifInfo = meta?["{GIF}"] as? [String: Any],
               let delayTime = gifInfo["DelayTime"] as? Double {
                delay = delayTime
               debugPrint(gifInfo)
            }
            
            var images = [UIImage]()
            let count = CGImageSourceGetCount(source)
            for i in 0..<count {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cgImage))
                }
            }
            DispatchQueue.main.async { [weak base] in
                base?.animationImages = images
                base?.animationDuration = Double(count) * delay
                base?.startAnimating()
                callback?(true)
            }
            
        }
    }
}

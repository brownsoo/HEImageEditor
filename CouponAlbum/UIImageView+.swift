//
//  UIImageView+.swift
//  HEExample
//
//  Created by hyonsoo on 8/11/24.
//

import UIKit
import ImageIO

extension UIImageView {
    func loadGif(url: URL) {
        DispatchQueue.global().async {
            guard let imageData = try? Data(contentsOf: url),
            let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
                return
            }
            
            let meta = imageData.he.metadataForImageData()
            var delay: Double = 0.1
            if let gifInfo = meta["{GIF}"] as? [String: Any],
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
            DispatchQueue.main.async {
                self.animationImages = images
                self.animationDuration = Double(count) * delay
                self.startAnimating()
            }
        }
    }
}

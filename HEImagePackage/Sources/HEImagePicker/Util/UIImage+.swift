//
//  UIImage+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit
import HECommon

internal extension UIImage {
    
    func solid(_ color: UIColor, width: CGFloat = 1, height: CGFloat = 1) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let result = renderer.image { c in
            color.setFill()
            c.fill(rect)
        }
        return result
    }
    
    func circle() -> UIImage {
        let size = self.size
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let result = renderer.image { c in
            let isPortrait = size.height > size.width
            let isLandscape = size.width > size.height
            let breadth = min(size.width, size.height)
            let breadthSize = CGSize(width: breadth, height: breadth)
            let breadthRect = CGRect(origin: .zero, size: breadthSize)
            let origin = CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0,
                                 y: isPortrait  ? floor((size.height - size.width) / 2) : 0)
            let circle = UIBezierPath(ovalIn: breadthRect)
            circle.addClip()
            let scale = self.scale
            let imageOrientation = self.imageOrientation
            if let cgImage = self.cgImage?.cropping(to: CGRect(origin: origin, size: breadthSize)) {
                UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation).draw(in: rect)
            }
        }
        return result
    }
    
    // Reduce image size further if needed targetImageSize is capped.
    func resizedImageIfNeeded() -> UIImage {
        if case let HEPickerImageSize.cappedTo(size: capped) = PickerConfig.targetImageSize {
            let size = cappedSize(for: self.size, cappedAt: capped)
            if let resizedImage = self.he.resize(size) {
                return resizedImage
            }
        }
        return self
    }
    
    fileprivate func cappedSize(for size: CGSize, cappedAt: CGFloat) -> CGSize {
        var cappedWidth: CGFloat = 0
        var cappedHeight: CGFloat = 0
        if size.width > size.height {
            // Landscape
            let heightRatio = size.height / size.width
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = cappedWidth * heightRatio
        } else if size.height > size.width {
            // Portrait
            let widthRatio = size.width / size.height
            cappedHeight = min(size.height, cappedAt)
            cappedWidth = cappedHeight * widthRatio
        } else {
            // Squared
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = min(size.height, cappedAt)
        }
        return CGSize(width: cappedWidth, height: cappedHeight)
    }
    
    func toCIImage() -> CIImage? {
        return self.ciImage ?? CIImage(cgImage: self.cgImage!)
    }
}

//
//  UIImage+HEImageEditor.swift
//  HEImageEditor
//

import UIKit
import Accelerate

public extension HEWrapper where Base: UIImage {
    // 회전 정정
    func fixOrientation() -> UIImage {
        if base.imageOrientation == .up {
            return base
        }
        
        var transform = CGAffineTransform.identity
        
        switch base.imageOrientation {
        case .down, .downMirrored:
            transform = CGAffineTransform(translationX: width, y: height)
            transform = transform.rotated(by: .pi)
        
        case .left, .leftMirrored:
            transform = CGAffineTransform(translationX: width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
            
        case .right, .rightMirrored:
            transform = CGAffineTransform(translationX: 0, y: height)
            transform = transform.rotated(by: -CGFloat.pi / 2)
            
        default:
            break
        }
        
        switch base.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        
        default:
            break
        }
        
        guard let cgImage = base.cgImage, let colorSpace = cgImage.colorSpace else {
            return base
        }
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue)
        context?.concatenate(transform)
        switch base.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        guard let newCgImage = context?.makeImage() else {
            return base
        }
        return UIImage(cgImage: newCgImage)
    }
    
    func rotate(orientation: UIImage.Orientation) -> UIImage {
        guard let imagRef = base.cgImage else {
            return base
        }
        let rect = CGRect(origin: .zero, size: CGSize(width: CGFloat(imagRef.width), height: CGFloat(imagRef.height)))
        
        var bnds = rect
        
        var transform = CGAffineTransform.identity
        
        switch orientation {
        case .up:
            return base
        case .upMirrored:
            transform = transform.translatedBy(x: rect.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .down:
            transform = transform.translatedBy(x: rect.width, y: rect.height)
            transform = transform.rotated(by: .pi)
        case .downMirrored:
            transform = transform.translatedBy(x: 0, y: rect.height)
            transform = transform.scaledBy(x: 1, y: -1)
        case .left:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: 0, y: rect.width)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .leftMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: rect.width)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .right:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .rightMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi / 2)
        @unknown default:
            return base
        }
        
        UIGraphicsBeginImageContext(bnds.size)
        let context = UIGraphicsGetCurrentContext()
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.scaleBy(x: -1, y: 1)
            context?.translateBy(x: -rect.height, y: 0)
        default:
            context?.scaleBy(x: 1, y: -1)
            context?.translateBy(x: 0, y: -rect.height)
        }
        context?.concatenate(transform)
        context?.draw(imagRef, in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? base
    }
    /// 가로 세로 교환
    func swapRectWidthAndHeight(_ rect: CGRect) -> CGRect {
        var r = rect
        r.size.width = rect.height
        r.size.height = rect.width
        return r
    }
    
    func rotate(degree: CGFloat) -> UIImage? {
        guard let cgImage = base.cgImage else {
            return nil
        }
        
        let rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let t = CGAffineTransform(rotationAngle: degree)
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size

        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()

        bitmap?.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)

        bitmap?.rotate(by: degree)

        bitmap?.scaleBy(x: 1.0, y: -1.0)
        bitmap?.draw(cgImage, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func mosaicImage() -> UIImage? {
        guard let currCgImage = base.cgImage else {
            return nil
        }
        
        let scale = 8 * width / UIScreen.main.bounds.width
        let currCiImage = CIImage(cgImage: currCgImage)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currCiImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        
        if let cgImg = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: base.size)) {
            return UIImage(cgImage: cgImg)
        } else {
            return nil
        }
    }
    
    func resize(_ size: CGSize, scale: CGFloat? = nil) -> UIImage? {
        if size.width <= 0 || size.height <= 0 {
            return nil
        }
        
        return UIGraphicsImageRenderer.he.renderImage(size: size) { format in
            format.scale = scale ?? base.scale
        } imageActions: { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func resize(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / base.size.width
        let newHeight = base.size.height * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let newRect = CGRect(origin: CGPoint(), size: newSize)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let result = renderer.image { c in
            base.draw(in: newRect)
        }
        return result
    }

    func resize(newHeight: CGFloat) -> UIImage {
        let scale = newHeight / base.size.height
        let newWidth = base.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let newRect = CGRect(origin: CGPoint(), size: newSize)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let result = renderer.image { c in
            base.draw(in: newRect)
        }
        return result
    }
    
    /// Resize image. Processing speed is better than resize(:) method
    /// - Parameters:
    ///   - size: Dest size of the image.
    ///   - scale: The scale factor of the image.
    ///   - bitsPerComponent: The number of bits allocated for a single color component of a bitmap image.
    ///   - bitsPerPixel: The number of bits allocated for a single pixel in a bitmap image. bitsPerComponent * 4
    func resize_vI(_ size: CGSize, scale: CGFloat? = nil, bitsPerComponent: UInt32 = 8, bitsPerPixel: UInt32 = 32) -> UIImage? {
        guard let cgImage = base.cgImage else { return nil }
        
        var format = vImage_CGImageFormat(
            bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            version: 0, decode: nil, renderingIntent: .defaultIntent
        )
        
        var sourceBuffer = vImage_Buffer()
        defer {
            if #available(iOS 13.0, *) {
                sourceBuffer.free()
            } else {
                sourceBuffer.data.deallocate()
            }
        }
        
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let destBytesPerRow = destWidth * bytesPerPixel
        
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
        
        // create a CGImage from vImage_Buffer
        guard let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue() else { return nil }
        guard error == kvImageNoError else { return nil }
        
        // create a UIImage
        return UIImage(cgImage: destCGImage, scale: scale ?? base.scale, orientation: base.imageOrientation)
    }
    
    func toCIImage() -> CIImage? {
        var ciImage = base.ciImage
        if ciImage == nil, let cgImage = base.cgImage {
            ciImage = CIImage(cgImage: cgImage)
        }
        return ciImage
    }
    
    func clipImage(angle: CGFloat, editRect: CGRect, isCircle: Bool) -> UIImage? {
        let a = ((Int(angle) % 360) - 360) % 360
        var newImage: UIImage = base
        if a == -90 {
            newImage = rotate(orientation: .left)
        } else if a == -180 {
            newImage = rotate(orientation: .down)
        } else if a == -270 {
            newImage = rotate(orientation: .right)
        }
        guard isCircle || editRect.size != newImage.size else {
            return newImage
        }
        
        let origin = CGPoint(x: -editRect.minX, y: -editRect.minY)
        let temp = UIGraphicsImageRenderer.he.renderImage(size: editRect.size) { format in
            format.scale = newImage.scale
        } imageActions: { context in
            if isCircle {
                context.addEllipse(in: CGRect(origin: .zero, size: editRect.size))
                context.clip()
            }
            newImage.draw(at: origin)
        }
        
        guard let cgi = temp.cgImage else { return temp }
        
        let clipImage = UIImage(cgImage: cgi, scale: newImage.scale, orientation: .up)
        return clipImage
    }
    
    func blurImage(level: CGFloat) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return nil
        }
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: "inputImage")
        blurFilter?.setValue(level, forKey: "inputRadius")
        
        guard let outputImage = blurFilter?.outputImage else {
            return nil
        }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    /// Compress an image to the max size
    /// - Warning: If the image has a transparent background color, this method will change it as jpeg doesn't support it.
    func compress(to maxSize: Int) -> UIImage {
        if let size = base.jpegData(compressionQuality: 1)?.count, size <= maxSize {
            return base
        }
        var min: CGFloat = 0
        var max: CGFloat = 1
        var data: Data?
        for _ in 0..<6 {
            let mid = (min + max) / 2
            data = base.jpegData(compressionQuality: mid)
            let compressSize = data?.count ?? 0
            if compressSize > maxSize {
                max = mid
            } else if compressSize < maxSize {
                min = mid
            } else {
                break
            }
        }
        guard let data = data else {
            return base
        }
        return UIImage(data: data) ?? base
    }

    func fillColor(_ color: UIColor) -> UIImage? {
        return UIGraphicsImageRenderer.he.renderImage(size: base.size) { format in
            format.scale = base.scale
        } imageActions: { context in
            let drawRect = CGRect(origin: .zero, size: base.size)
            color.setFill()
            UIRectFill(drawRect)
            base.draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
        }
    }
    
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
        let size = base.size
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
            let scale = base.scale
            let imageOrientation = base.imageOrientation
            if let cgImage = self.base.cgImage?.cropping(to: CGRect(origin: origin, size: breadthSize)) {
                UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation).draw(in: rect)
            }
        }
        return result
    }
    
    func alpha(value: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        return UIGraphicsImageRenderer(size: base.size, format: format).image { _ in
            base.draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        }
    }
}

public extension HEWrapper where Base: UIImage {
    var width: CGFloat {
        base.size.width
    }
    
    var height: CGFloat {
        base.size.height
    }
}

public extension HEWrapper where Base: UIImage {
    /// 사진 밝기, 대비, 채도 조정
    /// - Parameters:
    ///   - brightness: value in [-1, 1]
    ///   - contrast: value in [-1, 1]
    ///   - saturation: value in [-1, 1]
    func adjust(brightness: Float, contrast: Float, saturation: Float) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return base
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(HEConfiguration.AdjustTool.brightness.filterValue(brightness), forKey: HEConfiguration.AdjustTool.brightness.key)
        filter?.setValue(HEConfiguration.AdjustTool.contrast.filterValue(contrast), forKey: HEConfiguration.AdjustTool.contrast.key)
        filter?.setValue(HEConfiguration.AdjustTool.saturation.filterValue(saturation), forKey: HEConfiguration.AdjustTool.saturation.key)
        let outputCIImage = filter?.outputImage
        return outputCIImage?.he.toUIImage()
    }
}

extension HEWrapper where Base: UIImage {
    static func getImage(_ named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle.HEImageEditorBundle, compatibleWith: nil)
    }
}

public extension HEWrapper where Base: CIImage {
    func toUIImage() -> UIImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(base, from: base.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

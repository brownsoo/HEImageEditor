//
//  HEFaceDetection.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/12/24.
//

import Foundation
import Vision
import UIKit

public actor HEFaceDetection {
    
    struct Result {
        let id: UUID
        let frame: CGRect
        let quality: Float?
        let roll: Float?
    }
    
    func detect(from image: UIImage, orientation: UIImage.Orientation) async throws -> [Result] {
        guard let cgImage = image.cgImage else { return [] }
        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: orientation.toCGOrientation(),
                                            options: [:])
        
        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision2
#if targetEnvironment(simulator)
        if #available(iOS 17.0, *) {
          let allDevices = MLComputeDevice.allComputeDevices

          for device in allDevices {
            if(device.description.contains("MLCPUComputeDevice")){
              request.setComputeDevice(.some(device), for: .main)
              break
            }
          }

        } else {
          // Fallback on earlier versions
          request.usesCPUOnly = true
        }
#endif
        try handler.perform([request])
        guard var observations = request.results else {
            return []
        }
        trace("faces.count=\(observations.count)")
        observations.sort {
            ($0.faceCaptureQuality ?? 0) > ($1.faceCaptureQuality ?? 0)
        }
        let baseFrame = image.size
        let coordTransform = CGAffineTransform(scaleX: baseFrame.width, y: baseFrame.height)
        // Vision-to-UIKit coordinate transform. Vision is always relative to the lower-left corner.
        let finalTransform = coordTransform.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -1)

        return observations.map { face in
            let frame = face.boundingBox.applying(finalTransform)
            // FIXME: yaw, pitch, roll 의 2D 보정
            return Result(id: face.uuid, frame: frame, quality: face.faceCaptureQuality, roll: face.roll?.floatValue)
        }
    }
    
}

extension UIImage.Orientation {
    func toCGOrientation() -> CGImagePropertyOrientation {
        switch self {
        case .up:
            return CGImagePropertyOrientation.up
        case .down:
            return CGImagePropertyOrientation.down
        case .left:
            return CGImagePropertyOrientation.left
        case .right:
            return CGImagePropertyOrientation.right
        case .upMirrored:
            return CGImagePropertyOrientation.upMirrored
        case .downMirrored:
            return CGImagePropertyOrientation.downMirrored
        case .leftMirrored:
            return CGImagePropertyOrientation.leftMirrored
        case .rightMirrored:
            return CGImagePropertyOrientation.rightMirrored
        @unknown default:
            return CGImagePropertyOrientation.up
        }
    }
}

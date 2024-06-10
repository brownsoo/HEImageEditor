//
//  HEImageView.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import Photos
import UIKit

public protocol HEEditImageView: AnyObject {
    
    var isImageEditing: Bool { get }
    
    func done()
    func drawBtnClick()
    func startClipping()
    func imageStickerBtnClick()
    func textStickerBtnClick()
    func mosaicBtnClick()
    func filterBtnClick()
    func adjustBtnClick()
    
    func stopCurrentEditing()
    
//    var image: HEImage { get }
//    var effects: [HEEffect] { get }
//    var selectedEffect: HEEffect? { get }
//    
//    func setImage(_ image: HEImage)
//    func setImage(_ image: UIImage)
//    func setImage(asset: PHAsset)
//    
//    func addEffect(effect: HEEffect)
//    func removeEffect(effect: HEEffect)
//    func applyEffects(effects: [HEEffect])
//    func resetEffects()
//    func bringEffectToFront(effect: HEEffect)
//    func selectEffectAt(x: CGFloat, y: CGFloat) -> HEEffect?
    
//    func rotate(radian: CGFloat)
//    func crop(rect: CGRect)
    
    ///이미지 추출
    //func export(destination: URL) async throws -> URL
}

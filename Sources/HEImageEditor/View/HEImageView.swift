//
//  HEImageView.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import Photos
import UIKit

public protocol HEImageView {
    var image: HEImage { get }
    var effects: [HEEffect] { get }
    var selectedEffect: HEEffect? { get }
    
    func setImage(_ image: HEImage)
    func setImage(_ image: UIImage)
    func setImage(asset: PHAsset)
    
    func addEffect(effect: HEEffect)
    func removeEffect(effect: HEEffect)
    func applyEffects(effects: [HEEffect])
    func resetEffects()
    func bringEffectToFront(effect: HEEffect)
    func selectEffectAt(x: CGFloat, y: CGFloat) -> HEEffect?
    
    func rotate(radian: CGFloat)
    func crop(rect: CGRect)
    
    ///이미지 추출
    func export(destination: URL) async throws -> URL
}

public class ImageView: UIView, HEImageView {
    public private(set) var image: HEImage
    
    public var effects: [HEEffect]
    
    public var selectedEffect: HEEffect?
    
    public init(image: HEImage, effects: [HEEffect], selectedEffect: HEEffect? = nil) {
        self.image = image
        self.effects = effects
        self.selectedEffect = selectedEffect
        super.init(frame: image.frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setImage(_ image: HEImage) {
        self.image = image
    }
    
    public func setImage(_ image: UIImage) {
        
    }
    
    public func setImage(asset: PHAsset) {
        
    }
    
    public func addEffect(effect: HEEffect) {
        
    }
    
    public func removeEffect(effect: HEEffect) {
        
    }
    
    public func applyEffects(effects: [HEEffect]) {
        
    }
    
    public func resetEffects() {
        
    }
    
    public func bringEffectToFront(effect: HEEffect) {
        
    }
    
    public func selectEffectAt(x: CGFloat, y: CGFloat) -> HEEffect? {
        nil
    }
    
    public func rotate(radian: CGFloat) {
        
    }
    
    public func crop(rect: CGRect) {
        
    }
    
    public func export(destination: URL) async throws -> URL {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

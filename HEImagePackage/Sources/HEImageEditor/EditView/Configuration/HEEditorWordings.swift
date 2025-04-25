//
//  HEImageEditorLanguageDefine.swift
//  HEImageEditor
//

import Foundation

public struct HEEditorWordings {
    
    public var customRatio = localLanguageTextValue("custom ratio")
    public var original = localLanguageTextValue("original")
    public var circleRatio = localLanguageTextValue("circle ratio")
    public var rotate = localLanguageTextValue("rotate")
    public var completePick = localLanguageTextValue("complete pick")
    public var cancel = localLanguageTextValue("cancel")
    public var done = localLanguageTextValue("done")
    public var confirm = localLanguageTextValue("confirm")
    public var editFinish = localLanguageTextValue("editFinish")
    public var revert = localLanguageTextValue("revert")
    public var brightness = localLanguageTextValue("brightness")
    public var contrast = localLanguageTextValue("contrast")
    public var saturation = localLanguageTextValue("saturation")
    public var hudProcessing = localLanguageTextValue("hudProcessing")
    public var textInputPlaceholder = localLanguageTextValue("text_input_placeholder")
    
    public var alert = AlertMessage()
    
    public struct AlertMessage {
        public var clippingWithoutState = localLanguageTextValue("alert_clipping_without_state")
        public var cannotMoreImageStickers = localLanguageTextValue("cannot_more_image_stickers")
        public var cannotMoreTextStickers = localLanguageTextValue("cannot_more_text_stickers")
        
    }
    
    
}

func localLanguageTextValue(_ text: String) -> String {
    return Bundle.heLocalizedString(text)
}

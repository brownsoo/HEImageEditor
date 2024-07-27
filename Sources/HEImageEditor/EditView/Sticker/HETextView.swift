//
//  HETextView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 7/22/24.
//

import UIKit

class HETextView: UITextView {
    
    var placeholder: String? {
        willSet {
            if placeholder != newValue {
                cachedPlaceHolderFrame = nil
            }
        }
    }
    
    var placeholderAlignment: NSTextAlignment = .natural
    private var cachedAlignment: NSTextAlignment = .center
    private var placeholderLabel: UILabel?
    private var cachedPlaceHolderFrame: CGRect?
    
    func placeholderFrame() -> CGRect {
        if let cachedPlaceHolderFrame {
            return cachedPlaceHolderFrame
        }
        
        if placeholderLabel == nil {
            makePlaceholderLabel()
        }
        
        guard let label = placeholderLabel else {
            let pr =  CGRect(x: 0,
                             y: 0,
                             width: self.textContainerInset.width,
                             height: self.textContainerInset.height)
            return pr
        }
        
        
        label.sizeToFit()
        let rect = label.bounds
        // trace("cachedPlaceHolderFrame ====== > \(rect)")
        let pr = CGRect(x: 0,
                        y: 0,
                        width: rect.size.width + self.textContainerInset.width,
                        height: rect.size.height + self.textContainerInset.height)
        
        cachedPlaceHolderFrame = pr
        label.frame = pr
        return pr
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
    }
    
    private func makePlaceholderLabel() {
        guard placeholderLabel == nil else { return }
        cachedAlignment = self.textAlignment
        
        let label = UILabel()
        label.font = self.font
        label.textAlignment = self.textAlignment
        label.textColor = UIColor(white: 204 / 255.0, alpha: 1)
        label.text = placeholder
        self.addSubview(label)
        self.placeholderLabel = label
        
        label.frame = placeholderFrame()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged), name: UITextView.textDidChangeNotification, object: nil)
        
        firstLayoutPlaceholder()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if placeholder != nil {
            if placeholderLabel ==  nil {
                makePlaceholderLabel()
            }
        }
        
    }
    
    @objc
    private func textChanged() {
        guard let placeholder, !placeholder.isEmpty else { return }
        self.perform(#selector(self.showOrHidePlaceholder), with: nil)
    }
    
    @objc
    private func showOrHidePlaceholder() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showOrHidePlaceholder), object: nil)
        guard let label = placeholderLabel else { return }
        label.frame = placeholderFrame()
        
        let isEmpty = self.text.isEmpty
        let alignment = isEmpty ? placeholderAlignment : cachedAlignment
        if self.textAlignment != alignment {
            trace()
            self.textAlignment = alignment
            UIView.animate(withDuration: 0.1) {
                if isEmpty {
                    label.alpha = 1
                } else {
                    label.alpha = 0
                }
            }
        }
    }
    
    private func firstLayoutPlaceholder() {
        guard let label = placeholderLabel else { return }
        label.frame = placeholderFrame()
        
        let isEmpty = self.text.isEmpty
        let alignment = isEmpty ? placeholderAlignment : cachedAlignment
        
        self.textAlignment = alignment
        UIView.animate(withDuration: 0.1) {
            if isEmpty {
                label.alpha = 1
            } else {
                label.alpha = 0
            }
        }
    }
}


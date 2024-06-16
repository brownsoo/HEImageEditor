//
//  HEWeakProxy.swift
//  HEImageEditor
//

#if SWIFT_PACKAGE

import UIKit

class HEWeakProxy: NSObject {
    private weak var target: NSObjectProtocol?
    
    init(target: NSObjectProtocol) {
        self.target = target
        super.init()
    }
    
    class func proxy(target: NSObjectProtocol) -> HEWeakProxy {
        return HEWeakProxy(target: target)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }
}

#endif

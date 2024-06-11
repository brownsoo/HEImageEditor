//
//  ZLEditorManager.swift
//  HEImageEditor
//

import Foundation

/// 
public enum HEEditorAction {
    case draw(HEDrawPath)
    case eraser([HEDrawPath])
    case clip(oldStatus: HEClipStatus, newStatus: HEClipStatus)
    case sticker(oldState: HEStickerEffect?, newState: HEStickerEffect?)
    case mosaic(HEMosaicPath)
    case filter(oldFilter: HEFilter?, newFilter: HEFilter?)
    case adjust(oldStatus: HEAdjustStatus, newStatus: HEAdjustStatus)
}

protocol HEEditorManagerDelegate: AnyObject {
    func editorManager(_ manager: HEEditorActionManager, didUpdateActions actions: [HEEditorAction], redoActions: [HEEditorAction])
    
    func editorManager(_ manager: HEEditorActionManager, undoAction action: HEEditorAction)
    
    func editorManager(_ manager: HEEditorActionManager, redoAction action: HEEditorAction)
}

/// 액션 되돌리기, 다시실행 관리
class HEEditorActionManager {
    private(set) var actions: [HEEditorAction] = []
    private(set) var redoActions: [HEEditorAction] = []
    
    weak var delegate: HEEditorManagerDelegate?
    
    init(actions: [HEEditorAction] = []) {
        self.actions = actions
        self.redoActions = actions
    }
    
    func storeAction(_ action: HEEditorAction) {
        actions.append(action)
        redoActions = actions
        
        deliverUpdate()
    }
    
    func undoAction() {
        guard let preAction = actions.popLast() else { return }
        
        delegate?.editorManager(self, undoAction: preAction)
        deliverUpdate()
    }
    
    func redoAction() {
        guard actions.count < redoActions.count else { return }
        
        let action = redoActions[actions.count]
        actions.append(action)
        
        delegate?.editorManager(self, redoAction: action)
        deliverUpdate()
    }
    
    private func deliverUpdate() {
        delegate?.editorManager(self, didUpdateActions: actions, redoActions: redoActions)
    }
}

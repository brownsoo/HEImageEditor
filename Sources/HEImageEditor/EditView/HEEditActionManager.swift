//
//  HEEditorActionManager.swift
//  HEImageEditor
//

import Foundation

/// 
public enum HEEditAction {
    case draw(HEDrawPath)
    case eraser([HEDrawPath])
    case clip(oldStatus: HEClipStatus, newStatus: HEClipStatus)
    case sticker(oldState: HEStickerEffect?, newState: HEStickerEffect?)
    case mosaic(HEMosaicPath)
    case filter(oldFilter: HEFilter?, newFilter: HEFilter?)
    case adjust(oldStatus: HEAdjustStatus, newStatus: HEAdjustStatus)
}

protocol HEEditActionManagerDelegate: AnyObject {
    
    func editActionManager(_ manager: HEEditActionManager, didUpdateActions actions: [HEEditAction], redoActions: [HEEditAction])
    
    func editActionManager(_ manager: HEEditActionManager, undoAction action: HEEditAction)
    
    func editActionManager(_ manager: HEEditActionManager, redoAction action: HEEditAction)
}

/// 편집 동작 히스토리 관리
class HEEditActionManager {
    
    private(set) var actions: [HEEditAction] = []
    private(set) var redoActions: [HEEditAction] = []
    
    weak var delegate: HEEditActionManagerDelegate?
    
    init(actions: [HEEditAction] = []) {
        self.actions = actions
        self.redoActions = actions
    }
    
    func storeAction(_ action: HEEditAction) {
        actions.append(action)
        redoActions = actions
        
        deliverUpdate()
    }
    
    func undoAction() {
        guard let preAction = actions.popLast() else { return }
        
        delegate?.editActionManager(self, undoAction: preAction)
        deliverUpdate()
    }
    
    func redoAction() {
        guard actions.count < redoActions.count else { return }
        
        let action = redoActions[actions.count]
        actions.append(action)
        
        delegate?.editActionManager(self, redoAction: action)
        deliverUpdate()
    }
    
    private func deliverUpdate() {
        delegate?.editActionManager(self, didUpdateActions: actions, redoActions: redoActions)
    }
}

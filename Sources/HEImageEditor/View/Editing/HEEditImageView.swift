//
//  HEEditImageView.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import Photos
import UIKit

public protocol HEEditorActionListener: Equatable {
    func didUpdatedActions(_ actions: [HEEditorAction], redoActions: [HEEditorAction])
}


public protocol HEEditImageView: AnyObject {
    
    var isImageEditing: Bool { get }
    
    func cancel()
    func done()
    func undo()
    func redo()
    
    func startClipping()
    func startImageSticker()
    func startTextSticker()
    func startMosaicDrawing()
    func startDrawing()
    func startFiltering()
    func startAdjusting()
    
    func stopCurrentEditing()
    
    func addActionChangedListener<T: HEEditorActionListener>(_ listener: T)
    func removeActionChangedListener<T: HEEditorActionListener>(_ listener: T)
    func clearAllActionChangedListeners()
    
}

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

public protocol HEEditImageViewDelegate: AnyObject {
    func didFinishEditImage(_ editView: HEEditImageView, resultImage: UIImage, editId: String?, editModel: HEEditImageModel?) -> Void
    func cancelledEditImage(_ editView: HEEditImageView)
}


public extension HEEditImageViewDelegate {
    func cancelledEditImage(_ editView: HEEditImageView) {}
}

public protocol HEEditImageView: AnyObject {
    
    var selectedTool: HEConfiguration.EditTool? { get }
    var isImageEditing: Bool { get }
    /// 연속 편집 모드 여부
    ///
    /// - true: 편집이 종료되면, 대기 상태가 아닌 뷰를 종료한다. 
    /// - false: (기본값) 편집을 종료하면, 편집된 이미지를 표시하며 대기한다.
    var continuouslyMode: Bool { get set }
    
    /// 취소하고 화면 종료
    func cancel()
    /// 편집된 이미지 생성하고 화면 종료
    ///
    /// - delegate 실행: didFinishEditImage(resultImage: , editId: , editModel: )
    func done()
    
    
    /// 자르기, 회전 시작
    func startClipping()
    func startImageSticker()
    func startTextSticker()
    func startMosaicDrawing()
    func startDrawing()
    func startFiltering()
    func startAdjusting()
    
    /// 편집 상황을 종료
    func stopCurrentEditing()
    
    /// 편집 행위 되돌리기
    func undo()
    /// 편집 행위 재실행
    func redo()
    /// 편집 행위 변경사항 리스너 추가
    func addActionChangedListener<T: HEEditorActionListener>(_ listener: T)
    /// 편집 행위 변경사항 리스너 제거
    func removeActionChangedListener<T: HEEditorActionListener>(_ listener: T)
    /// 편집 행위 변경사항 모든 리스너 제거
    func clearAllActionChangedListeners()
    
}

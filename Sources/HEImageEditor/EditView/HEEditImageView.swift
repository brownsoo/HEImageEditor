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
    func didUpdatedActions(_ actions: [HEEditAction], redoActions: [HEEditAction])
}

public protocol HEEditImageViewDelegate: AnyObject {
    func didFinishEditImage(_ editView: HEEditImageView, resultImage: UIImage, editId: String?, editModel: HEEditState?) -> Void
    func cancelledEditImage(_ editView: HEEditImageView)
    func cannotAttachMoreImageStickers(_ editView: HEEditImageView)
    func cannotAttachMoreTextStickers(_ editView: HEEditImageView)
}


public extension HEEditImageViewDelegate {
    func cancelledEditImage(_ editView: HEEditImageView) {}
    func cannotAttachMoreTextStickers(_ editView: HEEditImageView) {}
    func cannotAttachMoreImageStickers(_ editView: HEEditImageView) {}
}

public protocol HEEditImageView: UIViewController {
    
    var selectedTool: HEImageEditorConfiguration.EditTool? { get }
    /// 편집 중
    ///
    /// - selectedTool 이 있음.
    var isImageEditing: Bool { get }
    
    /// 취소하고 화면 종료
    func cancel()
    /// 편집된 이미지 생성하고 화면 종료
    ///
    /// - delegate 실행: didFinishEditImage(resultImage: , editId: , editModel: )
    func done()
    
    
    /// 자르기, 회전 시작
    func startClipping()
    /// 이미지 스티커 시작
    func startImageSticker()
    /// 텍스트 스티커 시작
    func startTextSticker()
    /// 모자이크로 그리기 시작
    func startMosaicDrawing()
    /// 그리기 시작
    func startDrawing()
    /// 필터 시작
    func startFiltering()
    /// 색조 조정 시작 
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

//
//  HEPanGestureHelper.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit

enum DragDirection {
    case scroll
    case stop
    case up
    case down
}

class HEPanGestureHelper: NSObject, UIGestureRecognizerDelegate {
    
    var libView: HELibraryView!
    private let assetViewContainerOriginalConstraintTop: CGFloat = 0
    private var dragDirection = DragDirection.up
    private var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    private var cropBottomY: CGFloat  = 0.0
//    private var dragStartPos: CGPoint = .zero
    private var dragDiff: CGFloat = 0
    private var _isImageShown = true
    
    // The height constraint of the view with main selected image
    var topHeight: CGFloat {
        get {
            return libView.previewBoxConstraintTop?.constant ?? 0
        }
        set {
            if newValue >= libView.previewBoxMinimalVisibleHeight - libView.previewBox.bounds.height {
                libView.previewBoxConstraintTop?.constant = newValue
            }
        }
    }
    
    // Is the main image shown
    var isImageShown: Bool {
        get { return self._isImageShown }
        set {
            if newValue != isImageShown {
                self._isImageShown = newValue
                libView.previewBox.isShown = newValue
                // Update imageCropContainer
                libView.previewBox.reload()
            }
        }
    }
    
    func registerForPanGesture(on view: HELibraryView) {
        self.libView = view
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        topHeight = 0
    }
    
    public func resetToOriginalState() {
        topHeight = assetViewContainerOriginalConstraintTop
        animateView()
        dragDirection = .up
    }
    
    fileprivate func animateView() {
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: [.curveEaseInOut, .beginFromCurrentState],
                       animations: {
                        self.libView.refreshImageCurtainAlpha()
                        self.libView.layoutIfNeeded()
        }
            ,
                       completion: nil)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(ofTouch: 0, in: libView)
        // Desactivate pan on image when it is shown.
        if isImageShown {
            if p.y < libView.previewBox.frame.height {
                return false
            }
        }
        return true
    }
    
    @objc
    func panned(_ sender: UIPanGestureRecognizer) {
        let collBarHeight: CGFloat = 56
        let boxHeight = libView.previewBox.frame.height
        let currentPos = sender.location(in: libView)
        let overYLimitToStartMovingUp = currentPos.y * 1.4 < cropBottomY + collBarHeight
        
        switch sender.state {
        case .began:
            let view    = sender.view
            let loc     = sender.location(in: view)
            let subview = view?.hitTest(loc, with: nil)
            
            if subview == libView.currentZoomableView
                && topHeight == assetViewContainerOriginalConstraintTop {
                return
            }
            
            let dragStartPos = sender.location(in: view)
            cropBottomY = libView.previewBox.frame.origin.y + boxHeight
            dragDiff = dragStartPos.y - cropBottomY
            // Move
            if dragDirection == .stop {
                dragDirection = (topHeight == assetViewContainerOriginalConstraintTop)
                    ? .up
                    : .down
            }
//            trace("began- \(dragDirection)")
            // Scroll event of CollectionView is preferred.
            if (dragDirection == .up && dragStartPos.y < cropBottomY) || // 어셋박스 영역이거나
                (dragDirection == .down && dragStartPos.y > cropBottomY + collBarHeight) { // 콜랙션 리스트 영역이거나
//                trace("began- stop")
                dragDirection = .stop
            }
        case .changed:
            switch dragDirection {
            case .up:
                if currentPos.y < cropBottomY + collBarHeight {
                    topHeight = min(assetViewContainerOriginalConstraintTop,
                                    max(libView.previewBoxMinimalVisibleHeight - boxHeight,
                                        currentPos.y - boxHeight - dragDiff))
                        
                }
            case .down:
                if currentPos.y > cropBottomY {
                    topHeight =
                        min(assetViewContainerOriginalConstraintTop, 
                            currentPos.y - boxHeight - dragDiff)
                }
            case .scroll:
                topHeight =
                    libView.previewBoxMinimalVisibleHeight - boxHeight
                    + currentPos.y - imaginaryCollectionViewOffsetStartPosY
            case .stop:
                if libView.albumCollectionView.contentOffset.y < 0 {
                    dragDirection = .scroll
                    imaginaryCollectionViewOffsetStartPosY = currentPos.y
                }
            }
            
        default:
            imaginaryCollectionViewOffsetStartPosY = 0.0
            dragDiff = 0
            if sender.state == UIGestureRecognizer.State.ended && dragDirection == .stop {
                return
            }
            
            if overYLimitToStartMovingUp && isImageShown == false {
                // The largest movement
                topHeight =
                    libView.previewBoxMinimalVisibleHeight - boxHeight
                animateView()
                dragDirection = .down
            } else {
                // Get back to the original position
                resetToOriginalState()
            }
        }
        
        // Update isImageShown
        isImageShown = topHeight == assetViewContainerOriginalConstraintTop
    }
}

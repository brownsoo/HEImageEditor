//
//  HEEditImageModel.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/10/24.
//

import Foundation

/// 편집 대상 모델
public class HEEditImageModel: NSObject {
    /// 드로잉스
    public let drawPaths: [HEDrawPath]
    /// 모자잌스
    public let mosaicPaths: [HEMosaicPath]
    
    public let clipStatus: HEClipStatus?
    /// 색조 적용 상태
    public let adjustStatus: HEAdjustStatus
    
    public let selectFilter: HEFilter?
    
    public let stickers: [HEBaseStickertState]
    
    public let actions: [HEEditorAction]
    
    public init(
        drawPaths: [HEDrawPath] = [],
        mosaicPaths: [HEMosaicPath] = [],
        clipStatus: HEClipStatus? = nil,
        adjustStatus: HEAdjustStatus = HEAdjustStatus(),
        selectFilter: HEFilter? = nil,
        stickers: [HEBaseStickertState] = [],
        actions: [HEEditorAction] = []
    ) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.clipStatus = clipStatus
        self.adjustStatus = adjustStatus
        self.selectFilter = selectFilter
        self.stickers = stickers
        self.actions = actions
        super.init()
    }
}

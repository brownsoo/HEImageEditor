//
//  HEImageViewPager.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public protocol HEImageViewPager {
    var effectImageViews: [HEImageView] { get }
    var selectedEffectImageView: HEImageView? { get }
    var currentPage: Int { get set }
    var pageCount: Int { get }
    
    func addEffectImageView(imageView: HEImageView)
    func removeEffectImageView(imageView: HEImageView)
    func selectEffectImageView(imageView: HEImageView)
    func nextPage()
    func prevPage()
}

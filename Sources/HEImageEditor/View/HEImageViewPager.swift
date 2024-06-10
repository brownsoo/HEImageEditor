//
//  HEImageViewPager.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public protocol HEImageViewPager {
    var effectImageViews: [HEEditImageView] { get }
    var selectedEffectImageView: HEEditImageView? { get }
    var currentPage: Int { get set }
    var pageCount: Int { get }
    
    func addEffectImageView(imageView: HEEditImageView)
    func removeEffectImageView(imageView: HEEditImageView)
    func selectEffectImageView(imageView: HEEditImageView)
    func nextPage()
    func prevPage()
}

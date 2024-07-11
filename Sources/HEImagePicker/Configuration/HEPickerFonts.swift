//
//  HPFonts.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit

public struct HEPickerFonts {

    /// The font used in the picker title
    public var pickerTitleFont: UIFont = .boldSystemFont(ofSize: 17)

    /// The font used in the warning label of the LibraryView
    public var libaryWarningFont: UIFont = UIFont(name: "Helvetica Neue", size: 14)!

    /// The font used to show the duration in the LibraryViewCell
    public var durationFont: UIFont = .systemFont(ofSize: 11)
    public var captionFont: UIFont = .systemFont(ofSize: 11, weight: .bold)

    public var multipleSelectionIndicatorFont: UIFont = .systemFont(ofSize: 12, weight: .bold)

    public var albumCellTitleFont: UIFont = .systemFont(ofSize: 13, weight: .bold)

    public var albumCellNumberOfItemsFont: UIFont = .systemFont(ofSize: 14, weight: .bold)

    public var menuItemFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)

    public var filterNameFont: UIFont = .systemFont(ofSize: 11, weight: .regular)
    public var filterSelectionSelectedFont: UIFont = .systemFont(ofSize: 11, weight: .semibold)
    public var filterSelectionUnSelectedFont: UIFont = .systemFont(ofSize: 11, weight: .regular)

    public var cameraTimeElapsedFont: UIFont = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)

    public var navigationBarTitleFont: UIFont = .boldSystemFont(ofSize: 16)

    /// The font used in the UINavigationBar rightBarButtonItem
    public var rightBarButtonFont: UIFont? = .systemFont(ofSize: 14, weight: .bold)

    /// The font used in the UINavigationBar leftBarButtonItem
    public var leftBarButtonFont: UIFont?
}

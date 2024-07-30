//
//  HEImagePickerConfiguration.swift
//  HEImagePicker
//
//  Created by hyonsoo on 7/2/24.
//

import Foundation
import AVFoundation
import UIKit
import Photos

var PickerConfig: HEImagePickerConfiguration {
    HEImagePickerConfiguration.shared
}
/// 앨범 조회 미디어 타입
public enum HELibraryMediaType {
    case photo
    case video
    case photoAndVideo
}

/// 피커 소스
public enum HEPickerSource {
    /// 라이브러리 (필수)
    case libraryPick
    case photoCapture
    case videoCapture
}

public struct HEImagePickerConfiguration {
    
    public static var shared: HEImagePickerConfiguration = HEImagePickerConfiguration()
    
    public static var widthOniPad: CGFloat = -1
    
    public static var screenWidth: CGFloat {
        var screenWidth: CGFloat = UIScreen.main.bounds.width
        if UIDevice.current.userInterfaceIdiom == .pad && HEImagePickerConfiguration.widthOniPad > 0 {
            screenWidth = HEImagePickerConfiguration.widthOniPad
        }
        return screenWidth
    }

    /// If don't want to have logs from picker, set it to false.
    public var isDebugLogsEnabled: Bool = true

    public init() {}
    
    /// Library configuration
    public var library = Library()
    
    /// Video configuration
    public var video = HEConfigVideo()
    
    /// Use this property to modify the default wordings provided.
    public var wordings = HEPickerWordings()
    
    /// Use this property to modify the default icons provided.
    public var icons = HEPickerIcons()
    
    /// Use this property to modify the default colors provided.
    public var colors = HEPickerColors()

    /// Use this property to modify the default fonts provided
    public var fonts = HEPickerFonts()
    
    /// 미리보기 화면에서 줌 허용 여부
    ///
    /// defaults to true
    public var allowZoomablePreview = true
    
    /// 미리보기 영역에 이미지를 맞출지 여부
    ///
    /// - true(defaults) : 미리보기 영역을 채움
    /// - false : 이미지가 전부 보이도록 맞춤
    public var priviewScaleFit: Bool = true
    
    /// Allow to pick a previewing media without selection
    public var allowPickWithoutSelection = true
    
    /// Adds a edit button in preview container
    ///
    /// - if it touch on it, the below delegate is called.
    /// `func imagePicker(_ picker:, didSelectToEditItem:, inItems)`
    public var useEditPhoto: Bool = true

    /// Scroll to top if item is selected when preview box is hidden.
    public var scrollTopIfSelectedWhenPreviewIsHidden = false

    /// Set this to true if you want to force the camera output to be a squared image. Defaults to true
    public var onlySquareImagesFromCamera = true
    
    /// Adds a Video Trimmer step in the video taking process.  Defaults to true
    public var showsVideoTrimmer = true
    
    /// 카메라 촬영 후 사진 갤러리에 추가할 지 여부
    ///
    /// Defaults to true.
    public var shouldSaveNewPicturesToAlbum = true
    
    /// Defines the name of the album when saving pictures in the user's photo library.
    public var albumName = "하이클래스"
    
    /// Defines which source type can be pick.
    /// Default value is `[.libraryPick, .photoCapture, .videoCapture]`
    public var pickerSources: [HEPickerSource] = [.libraryPick, .photoCapture, .videoCapture]
    
    /// Ex: cappedTo:1024 will make sure images from the library or the camera will be
    /// resized to fit in a 1024x1024 box. Defaults to original image size.
    public var targetImageSize = HEPickerImageSize.original
    
    /// Adds a Overlay View to the camera
    public var overlayView: UIView?

    /// Defines if the navigation bar cancel button should be hidden when showing the picker. Default is false
    public var hidesCancelButton = false
    
    /// Defines if the status bar should be hidden when showing the picker. Default is true
    public var hidesStatusBar = true
    
    /// Defines if the bottom bar should be hidden when showing the picker. Default is false.
    public var hidesBottomBar = false

    /// Defines the preferredStatusBarAppearance
    public var preferredStatusBarStyle = UIStatusBarStyle.default
    
    /// Defines the text colour to be shown when a bottom option is selected
    public var bottomMenuItemSelectedTextColour: UIColor = .ypLabel
    
    /// Defines the text colour to be shown when a bottom option is unselected
    public var bottomMenuItemUnSelectedTextColour: UIColor = .ypSecondaryLabel
    
    /// Encapsulates library specific settings.
    public struct Library {
        
        public var options: PHFetchOptions?

        /// Set this to true if you want to force the library output to be a squared image. Defaults to false.
        public var onlySquare = false
        
        /// Allow to use clop 
        public var usingClop = false
        
        /// Sets the cropping style to square or not. Ignored if `onlySquare` is true. Defaults to true.
        public var isCropSquareByDefault = true
        
        /// Minimum width, to prevent selectiong too high images. Have sense if onlySquare is true and the image is portrait.
        public var minWidthForItem: CGFloat?
        
        /// Choose what media types are available in the library. Defaults to `.photo`.
        public var mediaType: HELibraryMediaType  = .photo

        /// Initial state of multiple selection button.
        public var defaultMultipleSelection = false

        /// Pre-selects the current item on setting multiple selection
        public var preSelectItemOnMultipleSelection = false

        /// 최대 선택가능한 미디어 수
        /// Anything superior than 1 will enable the multiple selection feature.
        public var maxNumberOfItems = 1
        
        /// Anything greater than 1 will desactivate live photo and video modes (library only) and
        /// force users to select at least the number of items defined.
        public var minNumberOfItems = 1

        /// Set the number of items per row in collection view. Defaults to 4.
        public var numberOfItemsInRow: Int = 4

        /// Set the spacing between items in collection view. Defaults to 1.5.
        public var spacingBetweenItems: CGFloat = 1.5

        /// Allow to skip the selections gallery when selecting the multiple media items. Defaults to false.
        public var skipSelectionsGallery = false
        
        /// Allow to preselected media items
        public var preselectedItems: [HEMediaItem]?
        
        /// 한번 선택으로 미디어를 선택할 지 여부
        public var addToSelectionBySigleTouch = true
        
    }

    /// Encapsulates video specific settings.
    public struct HEConfigVideo {
        
        /// 비디오 전체 압축을 할지 여부 (기본 true)
        ///
        /// - true: URL 값을 활용하지 말고, asset 을 활용해야 한다.
        public var disableCompressing: Bool = false
        
        /** Choose the videoCompression. Defaults to AVAssetExportPresetHighestQuality
         - "AVAssetExportPresetLowQuality"
         - "AVAssetExportPreset640x480"
         - "AVAssetExportPresetMediumQuality"
         - "AVAssetExportPreset1920x1080"
         - "AVAssetExportPreset1280x720"
         - "AVAssetExportPresetHighestQuality"
         - "AVAssetExportPresetAppleM4A"
         - "AVAssetExportPreset3840x2160"
         - "AVAssetExportPreset960x540"
         - "AVAssetExportPresetPassthrough" // without any compression
         */
        public var compression: String = AVAssetExportPresetHighestQuality
        
        /// Choose the result video extension if you trim or compress a video. Defaults to mov.
        public var fileType: AVFileType = .mp4
        
        /// Defines the time limit for recording videos.
        /// Default is 600 seconds.
        public var recordingTimeLimit: TimeInterval = 60.0 * 10
        
        /// Defines the size limit in bytes for recording videos.
        /// If this property is not nil, then the recording percentage line tracks buy this.
        /// In bytes. 100000000 is 100 MB.
        /// AVCaptureMovieFileOutput.maxRecordedFileSize.
        public var recordingSizeLimit: Int64?

        /// Minimum free space when recording videos.
        /// AVCaptureMovieFileOutput.minFreeDiskSpaceLimit.
        public var minFreeDiskSpaceLimit: Int64 = 1024 * 1024
        
        /// Defines the time limit for videos from the library.
        /// Defaults to 60 seconds.
        public var libraryTimeLimit: TimeInterval = 60.0
        
        /// Defines the minimum time for the video
        /// Defaults to 1 seconds.
        public var minimumTimeLimit: TimeInterval = 0.1
        
        /// max file size for video to select
        ///
        /// - default: 500MB
        public var maxVideoFileSize: Int64 = 500 * 1024 * 1024
        
        /// The maximum duration allowed for the trimming. Change it before setting the asset, as the asset preview
        /// - Tag: trimmerMaxDuration
        public var trimmerMaxDuration: Double = 60.0
        
        /// The minimum duration allowed for the trimming.
        /// The handles won't pan further if the minimum duration is attained.
        public var trimmerMinDuration: Double = 3.0

        /// Defines if the user skips the trimer stage,
        /// the video will be trimmed automatically to the maximum value of trimmerMaxDuration.
        /// This case occurs when the user already has a video selected and enables a
        /// multiselection to pick more than one type of media (video or image),
        /// so, the trimmer step becomes optional.
        /// - SeeAlso: [trimmerMaxDuration](x-source-tag://trimmerMaxDuration)
        public var automaticTrimToTrimmerMaxDuration: Bool = false
    }
    
}


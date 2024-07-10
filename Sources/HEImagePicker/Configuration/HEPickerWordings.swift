//
//  HPWordings.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation

public struct HEPickerWordings {
    
    public var permissionPopup = PermissionPopup()
    public var videoDurationPopup = VideoDurationPopup()

    public struct PermissionPopup {
        public var title = pickerLocalized("_permissionDeniedPopupTitle")
        public var message = pickerLocalized("_permissionDeniedPopupMessage")
        public var cancel = pickerLocalized("_permissionDeniedPopupCancel")
        public var grantPermission = pickerLocalized("_permissionDeniedPopupGrantPermission")
    }
    
    public struct VideoDurationPopup {
        public var title = pickerLocalized("_videoDurationTitle")
        public var tooShortMessage = pickerLocalized("_videoTooShort")
        public var tooLongMessage = pickerLocalized("_videoTooLong")
    }
    
    public var errorOnSaveVideoInLibrary = pickerLocalized("_errorOnSaveVideoInLibrary")
    public var errorOnSaveImageInLibrary = pickerLocalized("_errorOnSaveImageInLibrary")
    public var noPhotoLibraryAuthor = pickerLocalized("_noPhotoLibraryAuthor")
    public var noSupportCameraDevice = pickerLocalized("_noSupportCameraDevice")
    public var confirm = pickerLocalized("_confirm")
    public var allPhotos = pickerLocalized("_allPhotos")
    public var editPhoto = pickerLocalized("_editPhoto")
    public var attach = pickerLocalized("_attach")
    public var ok = pickerLocalized("_ok")
    public var done = pickerLocalized("_done")
    public var cancel = pickerLocalized("_cancel")
    public var save = pickerLocalized("_save")
    public var processing = pickerLocalized("_processing")
    public var trim = pickerLocalized("_trim")
    public var cover = pickerLocalized("_cover")
    public var albumsTitle = pickerLocalized("_albums")
    public var libraryTitle = pickerLocalized("_library")
    public var cameraTitle = pickerLocalized("_photo")
    public var videoTitle = pickerLocalized("_video")
    public var next = pickerLocalized("_next")
    public var filter = pickerLocalized("_filter")
    public var crop = pickerLocalized("_crop")
    public var warningMaxItemsLimit = pickerLocalized("_warningItemsLimit")
}

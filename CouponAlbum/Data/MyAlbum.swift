//
//  MyAlbum.swift
//  HEExample
//
//  Created by hyonsoo on 9/18/24.
//

import Foundation
import SwiftData

@Model
final class MyItem {
    var name: String
    var createDate: Date
    var thumbnail: URL?
    var album: MyAlbum?
    var media: MyMedia?
    
    init(name: String, thumbnail: URL? = nil, album: MyAlbum?, media: MyMedia?, createDate: Date = Date()) {
        self.name = name
        self.thumbnail = thumbnail
        self.album = album
        self.media = media
        self.createDate = createDate
    }
}


@Model
final class MyAlbum {
    @Attribute(.unique)
    var name: String
    var medias: [MyMedia]
    var createDate: Date
    
    init(name: String, medias: [MyMedia], createDate: Date = Date()) {
        self.name = name
        self.medias = medias
        self.createDate = createDate
    }
}


@Model
final class MyMedia {
    @Attribute(.unique)
    var id: String
    var title: String?
    var fileUrl: URL
    var createDate: Date
    var updateDate: Date
    var albums: [MyAlbum]
    
    init(id: String, fileUrl: URL, createDate: Date, albums: [MyAlbum]) {
        self.id = id
        self.fileUrl = fileUrl
        self.createDate = createDate
        self.updateDate = createDate
        self.albums = albums
    }
}

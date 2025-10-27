//
//  Video.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation

struct Video: Identifiable, Codable, Equatable {
    let id: Int
    let width: Int?
    let height: Int?
    let duration: Int?
    let image: URL?
    let user: VideoUser?
    let videoFiles: [VideoFile]?
    
    var isFavorite: Bool = false
    var isDownloaded: Bool = false
    var localFilePath: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, width, height, duration, image, user
        case videoFiles = "video_files"
    }
}

struct VideoUser: Codable, Equatable {
    let id: Int?
    let name: String?
}

struct VideoFile: Codable, Equatable {
    let id: Int
    let quality: String?
    let fileType: String?
    let link: URL
    
    enum CodingKeys: String, CodingKey {
        case id, quality
        case fileType = "file_type"
        case link
    }
}

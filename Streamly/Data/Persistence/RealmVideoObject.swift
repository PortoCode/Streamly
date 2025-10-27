//
//  RealmVideoObject.swift
//  Streamly
//
//  Created by Rodrigo Porto on 20/10/25.
//

import Foundation
import RealmSwift

final class RealmVideoObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var thumbnailURL: String = ""
    @Persisted var videoURL: String = ""
    @Persisted var duration: Int = 0
    @Persisted var author: String = ""
    @Persisted var isFavorite: Bool = false
    @Persisted var isDownloaded: Bool = false
    @Persisted var localFilePath: String? = nil
    
    convenience init(from video: Video) {
        self.init()
        self.id = video.id
        self.thumbnailURL = video.image?.absoluteString ?? ""
        self.videoURL = video.videoFiles?.first?.link.absoluteString ?? ""
        self.duration = video.duration ?? 0
        self.author = video.user?.name ?? ""
        self.isFavorite = video.isFavorite
        self.isDownloaded = video.isDownloaded
        self.localFilePath = video.localFilePath
    }
    
    func toVideo() -> Video {
        let videoFile = VideoFile(id: id,
                                  quality: nil,
                                  fileType: nil,
                                  link: URL(string: videoURL)!)
        return Video(id: id,
                     width: nil,
                     height: nil,
                     duration: duration,
                     image: URL(string: thumbnailURL)!,
                     user: VideoUser(id: nil, name: author),
                     videoFiles: [videoFile],
                     isFavorite: isFavorite,
                     isDownloaded: isDownloaded,
                     localFilePath: localFilePath)
    }
}

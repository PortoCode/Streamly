//
//  RealmManager.swift
//  Streamly
//
//  Created by Rodrigo Porto on 19/10/25.
//

import Foundation
import RealmSwift

final class RealmManager {
    static let shared = RealmManager()
    private init() {}
    
    func setupRealm() {
        var config = Realm.Configuration(schemaVersion: 1)
        Realm.Configuration.defaultConfiguration = config
        _ = try? Realm()
    }
}

final class RealmVideoObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var thumbnailURL: String = ""
    @objc dynamic var videoURL: String = ""
    @objc dynamic var duration: Int = 0
    @objc dynamic var author: String = ""
    @objc dynamic var isFavorite: Bool = false
    @objc dynamic var localFilePath: String? = nil
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(from video: Video) {
        self.init()
        self.id = video.id
        self.thumbnailURL = video.image?.absoluteString ?? ""
        self.videoURL = video.videoFiles?.first?.link.absoluteString ?? ""
        self.duration = video.duration ?? 0
        self.author = video.user?.name ?? ""
        self.isFavorite = video.isFavorite
    }
    
    func toVideo() -> Video {
        let videoFile = VideoFile(id: Int.random(in: 1...Int.max),
                                  quality: nil,
                                  fileType: nil,
                                  link: URL(string: videoURL)!)
        let video = Video(id: self.id,
                          width: nil,
                          height: nil,
                          duration: self.duration,
                          image: URL(string: thumbnailURL),
                          user: VideoUser(id: nil, name: self.author),
                          videoFiles: [videoFile],
                          isFavorite: self.isFavorite,
                          isDownloaded: localFilePath != nil)
        return video
    }
}

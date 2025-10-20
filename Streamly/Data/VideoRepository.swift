//
//  VideoRepository.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation
import Combine
import RealmSwift

protocol VideoRepositoryProtocol {
    func getPopularVideos() -> AnyPublisher<[Video], APIError>
    func saveFavorite(video: Video)
    func removeFavorite(videoId: Int)
    func fetchFavorites() -> [Video]
}

final class VideoRepository: VideoRepositoryProtocol {
    private let apiClient = PexelsAPIClient()
    private let realm = try! Realm()
    
    func getPopularVideos() -> AnyPublisher<[Video], APIError> {
        return apiClient.fetchPopularVideos()
            .map { $0.videos }
            .eraseToAnyPublisher()
    }
    
    func saveFavorite(video: Video) {
        let object = RealmVideoObject(from: video)
        try? realm.write {
            realm.add(object, update: .modified)
        }
    }
    
    func removeFavorite(videoId: Int) {
        if let object = realm.object(ofType: RealmVideoObject.self, forPrimaryKey: videoId) {
            try? realm.write {
                realm.delete(object)
            }
        }
    }
    
    func fetchFavorites() -> [Video] {
        let objects = realm.objects(RealmVideoObject.self)
        return objects.map { $0.toVideo() }
    }
}

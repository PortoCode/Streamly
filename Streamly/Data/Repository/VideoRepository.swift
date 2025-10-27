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
    func fetchVideos() -> AnyPublisher<[Video], Error>
    func save(_ video: Video)
    func remove(videoId: Int)
    func fetchPersistedVideos() -> [Video]
}

final class VideoRepository: VideoRepositoryProtocol {
    private let apiClient: PexelsAPIClient
    private let realmManager = RealmManager.shared
    
    init(apiClient: PexelsAPIClient = PexelsAPIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchVideos() -> AnyPublisher<[Video], Error> {
        apiClient.fetchPopularVideos()
            .map { $0.videos }
            .mapError { $0 as Error }
            .catch { _ in
                let cachedVideos = self.realmManager
                    .fetchAll(RealmVideoObject.self)
                    .map { $0.toVideo() }
                return Just(Array(cachedVideos))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func save(_ video: Video) {
        realmManager.save(RealmVideoObject(from: video))
    }
    
    func remove(videoId: Int) {
        realmManager.delete(RealmVideoObject.self, forPrimaryKey: videoId)
    }
    
    func fetchPersistedVideos() -> [Video] {
        let objects = realmManager.fetchAll(RealmVideoObject.self)
        return objects.map { $0.toVideo() }
    }
}

//
//  VideoRepository.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation
import Combine

protocol VideoRepositoryProtocol {
    func getPopularVideos() -> AnyPublisher<[Video], APIError>
}

final class VideoRepository: VideoRepositoryProtocol {
    private let apiClient = PexelsAPIClient()
    
    func getPopularVideos() -> AnyPublisher<[Video], APIError> {
        return apiClient.fetchPopularVideos()
            .map { $0.videos }
            .eraseToAnyPublisher()
    }
}

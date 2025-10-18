//
//  GetPopularVideosUseCase.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation
import Combine

final class GetPopularVideosUseCase {
    private let repository: VideoRepositoryProtocol
    
    init(repository: VideoRepositoryProtocol = VideoRepository()) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[Video], APIError> {
        return repository.getPopularVideos()
    }
}

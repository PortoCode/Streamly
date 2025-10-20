//
//  VideoListViewModel.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation
import Combine

final class VideoListViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let getPopularUseCase: GetPopularVideosUseCase
    private let repository: VideoRepositoryProtocol
    
    init(getPopularUseCase: GetPopularVideosUseCase = GetPopularVideosUseCase(), repository: VideoRepositoryProtocol = VideoRepository()) {
        self.getPopularUseCase = getPopularUseCase
        self.repository = repository
    }
    
    func fetchVideos() {
        isLoading = true
        errorMessage = nil
        
        getPopularUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.errorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] videos in
                let favorites = self?.repository.fetchFavorites() ?? []
                let favoriteIDs = Set(favorites.map { $0.id })
                let merged = videos.map { video -> Video in
                    var v = video
                    v.isFavorite = favoriteIDs.contains(video.id)
                    return v
                }
                self?.videos = merged
            }
            .store(in: &cancellables)
    }
    
    func toggleFavorite(_ video: Video) {
        var v = video
        v.isFavorite.toggle()
        if v.isFavorite {
            repository.saveFavorite(video: v)
        } else {
            repository.removeFavorite(videoId: v.id)
        }
        
        if let idx = videos.firstIndex(where: { $0.id == v.id }) {
            videos[idx] = v
        }
    }
}

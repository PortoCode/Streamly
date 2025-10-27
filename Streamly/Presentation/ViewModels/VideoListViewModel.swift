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
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let repository: VideoRepositoryProtocol
    
    init(repository: VideoRepositoryProtocol = VideoRepository()) {
        self.repository = repository
    }
    
    func fetchVideos() {
        isLoading = true
        
        repository.fetchVideos()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] apiVideos in
                guard let self else { return }
                
                let localVideos = repository.fetchPersistedVideos()
                let localById = Dictionary(uniqueKeysWithValues: localVideos.map { ($0.id, $0) })
                
                let merged = apiVideos.map { apiVideo -> Video in
                    if let local = localById[apiVideo.id] {
                        var mergedVideo = apiVideo
                        mergedVideo.isFavorite = local.isFavorite
                        mergedVideo.isDownloaded = local.isDownloaded
                        mergedVideo.isDownloaded = local.isDownloaded
                        mergedVideo.localFilePath = local.localFilePath
                        return mergedVideo
                    } else {
                        return apiVideo
                    }
                }
                
                self.videos = merged
            }
            .store(in: &cancellables)
    }
    
    func toggleFavorite(_ video: Video) {
        var v = video
        v.isFavorite.toggle()
        
        if !v.isFavorite && !v.isDownloaded {
            repository.remove(videoId: v.id)
        } else {
            repository.save(v)
        }
        
        if let idx = videos.firstIndex(where: { $0.id == v.id }) {
            videos[idx] = v
        }
    }
    
    func downloadVideo(_ video: Video) {
        VideoDownloadManager.shared.downloadVideo(video)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                if case let .failure(error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] localURL in
                guard let self else { return }
                
                if let index = videos.firstIndex(where: { $0.id == video.id }) {
                    videos[index].isDownloaded = true
                    videos[index].localFilePath = localURL.path
                    repository.save(videos[index])
                }
            }
            .store(in: &cancellables)
    }
    
    func removeDownload(_ video: Video) {
        VideoDownloadManager.shared.removeDownload(for: video)
        
        var v = video
        v.isDownloaded = false
        v.localFilePath = nil
        
        if !v.isFavorite {
            repository.remove(videoId: v.id)
        } else {
            repository.save(v)
        }
        
        if let idx = videos.firstIndex(where: { $0.id == v.id }) {
            videos[idx] = v
        }
    }
}

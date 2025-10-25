//
//  VideoDownloadManager.swift
//  Streamly
//
//  Created by Rodrigo Porto on 20/10/25.
//

import Foundation
import Combine

final class VideoDownloadManager {
    static let shared = VideoDownloadManager()
    
    private var cancellables = Set<AnyCancellable>()
    private init() {}
    
    func downloadVideo(_ video: Video) -> AnyPublisher<URL, Error> {
        let fileName = "\(video.id).mp4"
        let destinationURL = FileManager.localFileURL(for: fileName)
        
        if FileManager.fileExists(withName: fileName) {
            return Just(destinationURL)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        guard let videoURL = video.videoFiles?.first?.link else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let request = URLRequest(url: videoURL)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> URL in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                try data.write(to: destinationURL)
                try FileManager.excludeFromBackup(url: destinationURL) // avoid iCloud backup
                
                let updatedVideo = RealmVideoObject(from: video)
                updatedVideo.isDownloaded = true
                updatedVideo.localFilePath = destinationURL.path
                
                RealmManager.shared.save(updatedVideo)
                
                return destinationURL
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func removeDownload(for video: Video) {
        let fileName = "\(video.id).mp4"
        let fileURL = FileManager.localFileURL(for: fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Failed to remove file: \(error)")
            }
        }
        
        let updatedVideo = RealmVideoObject(from: video)
        updatedVideo.isDownloaded = false
        updatedVideo.localFilePath = nil
        RealmManager.shared.save(updatedVideo)
    }
}

//
//  VideoPlayerContainer.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import SwiftUI
import AVKit

struct VideoPlayerContainer: UIViewControllerRepresentable {
    let video: Video
    
    func makeUIViewController(context: Context) -> UIViewController {
        if let localPath = video.localFilePath,
           FileManager.default.fileExists(atPath: localPath) {
            let localURL = URL(fileURLWithPath: localPath)
            return VideoPlayerViewController(url: localURL)
        }
        
        if let remoteURL = video.videoFiles?
            .sorted(by: { ($0.quality ?? "") > ($1.quality ?? "") })
            .first?.link {
            return VideoPlayerViewController(url: remoteURL)
        }
        
        let emptyVC = UIViewController()
        emptyVC.view.backgroundColor = .black
        let label = UILabel()
        label.text = "Video unavailable"
        label.textColor = .white
        label.textAlignment = .center
        label.frame = emptyVC.view.bounds
        emptyVC.view.addSubview(label)
        return emptyVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

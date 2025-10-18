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
        guard let link = video.videoFiles?.sorted(by: { $0.quality ?? "" > $1.quality ?? "" }).first?.link else {
            return UIViewController()
        }
        
        return VideoPlayerViewController(url: link)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

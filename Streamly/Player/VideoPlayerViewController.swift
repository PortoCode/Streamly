//
//  VideoPlayerViewController.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import UIKit
import AVKit

final class VideoPlayerViewController: UIViewController {
    private let videoURL: URL
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    init(url: URL) {
        self.videoURL = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPlayer()
        setupControls()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
    
    private func setupPlayer() {
        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        if let layer = playerLayer {
            view.layer.addSublayer(layer)
        }
        player?.play()
    }
    
    private func setupControls() {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Pause", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(togglePlayPause(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -36),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func togglePlayPause(_ sender: UIButton) {
        guard let p = player else { return }
        if p.timeControlStatus == .playing {
            p.pause()
            sender.setTitle("Play", for: .normal)
        } else {
            p.play()
            sender.setTitle("Pause", for: .normal)
        }
    }
    
    deinit {
        player?.pause()
        player = nil
    }
}

#if DEBUG
import SwiftUI

struct VideoPlayerViewController_Previews: PreviewProvider {
    static var previews: some View {
        let video = Video(
            id: 1,
            width: 1920,
            height: 1080,
            duration: 10,
            image: URL(string: "https://www.w3schools.com/html/pic_trulli.jpg"),
            user: VideoUser(id: 1, name: "Preview User"),
            videoFiles: [
                VideoFile(
                    id: 1,
                    quality: "1080p",
                    fileType: "mp4",
                    link: URL(string: "https://www.w3schools.com/html/mov_bbb.mp4")!
                )
            ],
            isFavorite: false,
            isDownloaded: false,
            localFilePath: nil
        )

        return VideoPlayerContainer(video: video)
            .edgesIgnoringSafeArea(.all)
            .previewDisplayName("Video Player (via Container)")
    }
}
#endif

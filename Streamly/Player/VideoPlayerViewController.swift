//
//  VideoPlayerViewController.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import UIKit
import AVKit

final class VideoPlayerViewController: UIViewController {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var progressSlider: UISlider?
    private var timeObserver: Any?
    
    private let videoURL: URL
    private let autoplay: Bool
    private var currentSpeed: Float = 1.0
    
    init(url: URL, autoplay: Bool = false) {
        self.videoURL = url
        self.autoplay = autoplay
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
        setupProgressObserver()
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
        if autoplay {
            player?.play()
        }
    }
    
    private func setupControls() {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(slider)
        self.progressSlider = slider
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(
            autoplay
            ? UIImage(systemName: "pause.fill")
            : UIImage(systemName: "play.fill"),
            for: .normal
        )
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(togglePlayPause(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        let speedButton = UIButton(type: .system)
        speedButton.translatesAutoresizingMaskIntoConstraints = false
        speedButton.setTitle("1x", for: .normal)
        speedButton.setTitleColor(.white, for: .normal)
        speedButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        speedButton.addTarget(self, action: #selector(toggleSpeed(_:)), for: .touchUpInside)
        view.addSubview(speedButton)
        
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            slider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -36),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 44),
            
            speedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            speedButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }
    
    private func setupProgressObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.updateProgress(time)
        }
    }
    
    private func updateProgress(_ currentTime: CMTime) {
        guard let duration = player?.currentItem?.duration,
              duration.isNumeric else { return }
        
        let durationSeconds = CMTimeGetSeconds(duration)
        let currentSeconds = CMTimeGetSeconds(currentTime)
        
        progressSlider?.maximumValue = Float(durationSeconds)
        progressSlider?.value = Float(currentSeconds)
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        let newTime = CMTime(seconds: Double(slider.value), preferredTimescale: 600)
        player?.seek(to: newTime)
    }
    
    @objc private func togglePlayPause(_ sender: UIButton) {
        guard let p = player else { return }
        if p.timeControlStatus == .playing {
            p.pause()
            sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            p.play()
            sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    @objc private func toggleSpeed(_ sender: UIButton) {
        switch currentSpeed {
        case 1.0:
            currentSpeed = 1.5
            sender.setTitle("1.5x", for: .normal)
        case 1.5:
            currentSpeed = 2.0
            sender.setTitle("2x", for: .normal)
        default:
            currentSpeed = 1.0
            sender.setTitle("1x", for: .normal)
        }
        
        player?.rate = currentSpeed
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
        
        return VideoPlayerContainer(video: video, autoplay: false)
            .edgesIgnoringSafeArea(.all)
            .previewDisplayName("Video Player (via Container)")
    }
}
#endif

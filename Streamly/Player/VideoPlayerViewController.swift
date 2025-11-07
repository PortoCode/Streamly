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
    private var playPauseButton: UIButton?
    private var speedButton: UIButton?
    private var timeLabel: UILabel?
    
    private let videoURL: URL
    private let autoplay: Bool
    private let defaultTimescale: CMTimeScale = 600
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
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .darkGray
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(slider)
        self.progressSlider = slider
        
        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        timeLabel.text = "0:00 / 0:00"
        timeLabel.textAlignment = .center
        view.addSubview(timeLabel)
        self.timeLabel = timeLabel
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        view.addSubview(stackView)
        
        let backwardBtn = createControlButton(
            imageName: "gobackward.10",
            target: self,
            action: #selector(skipBackward(_:))
        )
        
        let playPauseBtn = createControlButton(
            imageName: autoplay ? "pause.fill" : "play.fill",
            target: self,
            action: #selector(togglePlayPause(_:))
        )
        self.playPauseButton = playPauseBtn
        
        let forwardBtn = createControlButton(
            imageName: "goforward.10",
            target: self,
            action: #selector(skipForward(_:))
        )
        
        stackView.addArrangedSubview(backwardBtn)
        stackView.addArrangedSubview(playPauseBtn)
        stackView.addArrangedSubview(forwardBtn)
        
        let speedBtn = UIButton(type: .system)
        speedBtn.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.title = "1x"
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        config.background.strokeColor = .white
        config.background.strokeWidth = 1
        config.background.cornerRadius = 6
        speedBtn.configuration = config
        speedBtn.addTarget(self, action: #selector(toggleSpeed(_:)), for: .touchUpInside)
        view.addSubview(speedBtn)
        self.speedButton = speedBtn
        
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            slider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            
            timeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            
            speedBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            speedBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
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
        
        if !progressSlider!.isTracking {
            progressSlider?.value = Float(currentSeconds)
        }
        
        timeLabel?.text = "\(formatTime(currentTime)) / \(formatTime(duration))"
    }
    
    private func formatTime(_ time: CMTime) -> String {
        let totalSeconds = Int(CMTimeGetSeconds(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func createControlButton(imageName: String, target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = .white
        button.addTarget(target, action: action, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 50).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        let newTime = CMTime(seconds: Double(slider.value), preferredTimescale: defaultTimescale)
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
    
    @objc private func skipBackward(_ sender: UIButton) {
        guard let player = player else { return }
        let newTime = CMTimeAdd(
            player.currentTime(),
            CMTime(seconds: -10, preferredTimescale: defaultTimescale)
        )
        player.seek(to: newTime)
    }

    @objc private func skipForward(_ sender: UIButton) {
        guard let player = player else { return }
        let newTime = CMTimeAdd(
            player.currentTime(),
            CMTime(seconds: 10, preferredTimescale: defaultTimescale)
        )
        player.seek(to: newTime)
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
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
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

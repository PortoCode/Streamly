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
    private var muteButton: UIButton?
    private var fullscreenButton: UIButton?
    
    private var isFullscreen = false
    private var controlsVisible = true
    private var controlsHideTimer: Timer?
    private var controlElements: [UIView] = []
    
    private let videoURL: URL
    private let autoplay: Bool
    private let defaultTimescale: CMTimeScale = 600
    private var currentSpeed: PlaybackSpeed = .normal
    private let progressUpdateInterval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    
    private enum PlaybackSpeed: Float, CaseIterable {
        case normal = 1.0
        case oneAndHalf = 1.5
        case double = 2.0
        
        var label: String {
            switch self {
            case .normal: return "1x"
            case .oneAndHalf: return "1.5x"
            case .double: return "2x"
            }
        }
        
        func next() -> PlaybackSpeed {
            let all = PlaybackSpeed.allCases
            let index = all.firstIndex(of: self)!
            return index == all.count - 1 ? all[0] : all[index + 1]
        }
    }
    
    private enum SkipInterval {
        static let short: Double = 10
        static let long: Double = 30
    }
    
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
        view.backgroundColor = .systemBackground
        setupPlayer()
        setupControls()
        setupProgressObserver()
        setupGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        playerLayer?.frame = CGRect(origin: .zero, size: size)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    private func setupPlayer() {
        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        
        guard let layer = playerLayer else { return }
        view.layer.addSublayer(layer)
        
        if autoplay {
            player?.play()
        }
    }
    
    private func setupControls() {
        setupProgressSlider()
        setupTimeLabel()
        
        let backgroundView = setupControlsBackground()
        let controlsStack = setupPlaybackButtons(in: backgroundView)
        
        setupSpeedButton()
        setupMuteButton()
        setupFullscreenButton()
        
        activateControlsConstraints(
            slider: progressSlider!,
            timeLabel: timeLabel!,
            backgroundView: backgroundView,
            stackView: controlsStack
        )
    }
    
    private func setupProgressSlider() {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .darkGray
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        view.addSubview(slider)
        progressSlider = slider
        registerControl(slider)
    }
    
    private func setupTimeLabel() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        label.text = "0:00 / 0:00"
        
        view.addSubview(label)
        timeLabel = label
        registerControl(label)
    }
    
    private func setupControlsBackground() -> UIView {
        let bg = UIView()
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.backgroundColor = UIColor(white: 0, alpha: 0.5)
        bg.layer.cornerRadius = 10
        bg.layer.masksToBounds = true
        
        view.addSubview(bg)
        registerControl(bg)
        
        return bg
    }
    
    private func setupPlaybackButtons(in backgroundView: UIView) -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.distribution = .equalSpacing
        
        let back = createControlButton(imageName: "gobackward.10",
                                       target: self,
                                       action: #selector(skipBackward(_:)))
        
        let playPause = createControlButton(imageName: autoplay ? "pause.fill" : "play.fill",
                                            target: self,
                                            action: #selector(togglePlayPause(_:)))
        self.playPauseButton = playPause
        
        let forward = createControlButton(imageName: "goforward.10",
                                          target: self,
                                          action: #selector(skipForward(_:)))
        
        stack.addArrangedSubview(back)
        stack.addArrangedSubview(playPause)
        stack.addArrangedSubview(forward)
        
        backgroundView.addSubview(stack)
        return stack
    }
    
    private func setupSpeedButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.plain()
        config.title = "1x"
        config.baseForegroundColor = .systemBlue
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return out
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        config.background.strokeColor = .systemBlue
        config.background.strokeWidth = 1
        config.background.cornerRadius = 6
        
        btn.configuration = config
        btn.addTarget(self, action: #selector(toggleSpeed(_:)), for: .touchUpInside)
        
        view.addSubview(btn)
        speedButton = btn
        registerControl(btn)
    }
    
    private func setupMuteButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "speaker.fill"), for: .normal)
        btn.tintColor = .systemBlue
        btn.addTarget(self, action: #selector(toggleMute(_:)), for: .touchUpInside)
        
        view.addSubview(btn)
        muteButton = btn
        registerControl(btn)
    }
    
    private func setupFullscreenButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        btn.tintColor = .systemBlue
        btn.addTarget(self, action: #selector(toggleFullscreen(_:)), for: .touchUpInside)
        
        view.addSubview(btn)
        fullscreenButton = btn
        registerControl(btn)
    }
    
    private func activateControlsConstraints(slider: UISlider, timeLabel: UILabel, backgroundView: UIView, stackView: UIStackView) {
        guard let muteButton = muteButton,
              let fullscreenButton = fullscreenButton,
              let speedButton = speedButton else {
            return
        }
        
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            slider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            
            timeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            backgroundView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            backgroundView.widthAnchor.constraint(equalToConstant: 250),
            backgroundView.heightAnchor.constraint(equalToConstant: 60),
            
            stackView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            
            muteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            muteButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            fullscreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            fullscreenButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            speedButton.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -12),
            speedButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }
    
    private func registerControl(_ view: UIView) {
        controlElements.append(view)
    }
    
    private func setupProgressObserver() {
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: progressUpdateInterval,
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
    
    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        view.addGestureRecognizer(singleTap)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
    }
    
    private func setControlsVisible(_ visible: Bool, animated: Bool = true) {
        controlsVisible = visible
        
        controlsHideTimer?.invalidate()
        
        let duration = animated ? 0.3 : 0
        UIView.animate(withDuration: duration) {
            self.controlElements.forEach { $0.alpha = visible ? 1.0 : 0.0 }
        }
        
        if visible {
            controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                if self?.player?.timeControlStatus == .playing {
                    self?.setControlsVisible(false, animated: true)
                }
            }
        }
    }
    
    private func resetControlsHideTimer() {
        controlsHideTimer?.invalidate()
        
        if controlsVisible && player?.timeControlStatus == .playing {
            controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.setControlsVisible(false, animated: true)
            }
        }
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
        resetControlsHideTimer()
        let newTime = CMTime(seconds: Double(slider.value), preferredTimescale: defaultTimescale)
        player?.seek(to: newTime)
    }
    
    @objc private func togglePlayPause(_ sender: UIButton) {
        resetControlsHideTimer()
        guard let p = player else { return }
        if p.timeControlStatus == .playing {
            p.pause()
            sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
            setControlsVisible(true, animated: false)
        } else {
            p.play()
            sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    @objc private func skipBackward(_ sender: UIButton) {
        resetControlsHideTimer()
        guard let player = player else { return }
        let newTime = CMTimeAdd(
            player.currentTime(),
            CMTime(seconds: -SkipInterval.short, preferredTimescale: defaultTimescale)
        )
        player.seek(to: newTime)
    }
    
    @objc private func skipForward(_ sender: UIButton) {
        resetControlsHideTimer()
        guard let player = player else { return }
        let newTime = CMTimeAdd(
            player.currentTime(),
            CMTime(seconds: SkipInterval.short, preferredTimescale: defaultTimescale)
        )
        player.seek(to: newTime)
    }
    
    @objc private func toggleSpeed(_ sender: UIButton) {
        resetControlsHideTimer()
        
        currentSpeed = PlaybackSpeed(rawValue: currentSpeed.rawValue)!.next()
        sender.setTitle(currentSpeed.label, for: .normal)
        player?.rate = currentSpeed.rawValue
    }
    
    @objc private func toggleMute(_ sender: UIButton) {
        resetControlsHideTimer()
        guard let player = player else { return }
        let isMuted = player.volume == 0
        player.volume = isMuted ? 1.0 : 0
        sender.setImage(UIImage(systemName: isMuted ? "speaker.fill" : "speaker.slash.fill"), for: .normal)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let button = playPauseButton else { return }
        togglePlayPause(button)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        setControlsVisible(!controlsVisible, animated: true)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let player = player else { return }
        
        if !controlsVisible {
            setControlsVisible(true, animated: true)
        }
        
        if gesture.direction == .left {
            let newTime = CMTimeAdd(
                player.currentTime(),
                CMTime(seconds: SkipInterval.long, preferredTimescale: defaultTimescale)
            )
            player.seek(to: newTime)
        } else if gesture.direction == .right {
            let newTime = CMTimeAdd(
                player.currentTime(),
                CMTime(seconds: -SkipInterval.long, preferredTimescale: defaultTimescale)
            )
            player.seek(to: newTime)
        }
        
        resetControlsHideTimer()
    }
    
    @objc private func toggleFullscreen(_ sender: UIButton) {
        isFullscreen.toggle()
        
        AppDelegate.orientationLock = isFullscreen ? .landscapeRight : .portrait
        
        setNeedsUpdateOfSupportedInterfaceOrientations()
        
        if #available(iOS 16.0, *) {
            guard let windowScene = view.window?.windowScene else { return }
            
            let mask: UIInterfaceOrientationMask = isFullscreen ? .landscapeRight : .portrait
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
            
            DispatchQueue.main.async {
                windowScene.requestGeometryUpdate(preferences) { error in
                    print("Error updating geometry: \(error.localizedDescription)")
                }
            }
        } else {
            let orientation = isFullscreen
            ? UIInterfaceOrientation.landscapeRight.rawValue
            : UIInterfaceOrientation.portrait.rawValue
            
            UIDevice.current.setValue(orientation, forKey: "orientation")
        }
        
        let imageName = isFullscreen
        ? "arrow.down.right.and.arrow.up.left"
        : "arrow.up.left.and.arrow.down.right"
        
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    deinit {
        controlsHideTimer?.invalidate()
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

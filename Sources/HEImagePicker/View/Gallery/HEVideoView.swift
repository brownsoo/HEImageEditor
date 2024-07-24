//
//  HEVideoView.swift
//  HEImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Ported by 브라운수 on 7/2/24.
//

import UIKit
import AVFoundation

/// A video view that contains video layer, supports play, pause and other actions.
/// Supports xib initialization.
public class HEVideoView: UIView {
    public let playIconView = UIImageView(image: nil)
    
    internal let playerView = UIView()
    internal let playerLayer = AVPlayerLayer()
    internal var previewImageView = UIImageView()
    
    public var player: AVPlayer {
        guard let player = playerLayer.player else {
            return AVPlayer()
        }
        return player
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    internal func setup() {
        let singleTapGR = UITapGestureRecognizer(target: self,
                                                 action: #selector(singleTap))
        singleTapGR.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGR)
        
        playerView.alpha = 0
        playIconView.alpha = 0
        playIconView.contentMode = .center
        
        playerLayer.videoGravity = .resizeAspect
        previewImageView.contentMode = .scaleAspectFit
        addSubview(previewImageView)
        addSubview(playerView)
        addSubview(playIconView)
        
        previewImageView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
        playerView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
        playIconView.makeConstraints { v in
            v.centerXAnchorConstraintToSuperview()
            v.centerYAnchorConstraintToSuperview()
            if let size = PickerConfig.icons.playImage?.size {
                v.backgroundColor = .black.withAlphaComponent(0.3)
                v.sizeAnchorConstraintTo(size.width * 2)
                v.layer.cornerRadius = size.width
                v.layer.masksToBounds = true
            }
        }
        
        playerView.layer.addSublayer(playerLayer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = playerView.bounds
    }
    
    @objc internal func singleTap() {
        pauseUnpause()
    }
    
    @objc public func playerItemDidReachEnd(_ note: Notification) {
        player.actionAtItemEnd = .none
        player.seek(to: CMTime.zero)
        player.play()
    }
}

// MARK: - Video handling
extension HEVideoView {
    /// The main load video method
    public func loadVideo<T>(_ item: T) {
        var player: AVPlayer
        
        switch item.self {
        case let video as HEMediaVideo:
            player = AVPlayer(url: video.url)
        case let url as URL:
            player = AVPlayer(url: url)
        case let playerItem as AVPlayerItem:
            player = AVPlayer(playerItem: playerItem)
        default:
            return
        }
        
        playerLayer.player = player
        playerView.alpha = 1
        showPlayImage(show: true)
        setNeedsLayout()
    }
    
    /// Convenience func to pause or unpause video dependely of state
    public func pauseUnpause() {
        (player.rate == 0.0) ? play() : pause()
    }

    /// Mute or unmute the video
    public func muteUnmute() {
        player.isMuted = !player.isMuted
    }
    
    public func play() {
        trace()
        player.play()
        showPlayImage(show: false)
        addReachEndObserver()
    }
    
    public func pause() {
        trace()
        player.pause()
        showPlayImage(show: true)
    }
    
    public func stop() {
        trace()
        player.pause()
        player.seek(to: CMTime.zero)
        showPlayImage(show: true)
        removeReachEndObserver()
    }
    
    public func deallocate() {
        playerLayer.player = nil
        playIconView.image = nil
    }
}

// MARK: - Other API
extension HEVideoView {
    public func setPreviewImage(_ image: UIImage?) {
        previewImageView.image = image
    }
    
    /// Shows or hide the play image over the view.
    public func showPlayImage(show: Bool) {
        self.playIconView.image = PickerConfig.icons.playImage?.withTintColor(.white, renderingMode: .alwaysOriginal)
        UIView.animate(withDuration: 0.1) {
            self.playIconView.alpha = show ? 0.8 : 0
        }
    }
    
    public func addReachEndObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    /// Removes the observer for AVPlayerItemDidPlayToEndTime. Could be needed to implement own observer
    public func removeReachEndObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: player.currentItem)
    }
}

//
//  VideoView.swift
//  Stories
//
//  Created by Aryan Sharma on 28/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit
import AVKit

///Custom UView which has an instance of AVplayer inside a AVPlayerLayer.
class VideoView: UIView {
    ///AVPlayerLayer containing the AVPlayer.
    var playerLayer: AVPlayerLayer
    
    ///AVPlayer used to play a video type story.
    var snapVideo: AVPlayer = {
        let av = AVPlayer()
        return av
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = frame
    }
    
    override init(frame: CGRect) {
        self.playerLayer = AVPlayerLayer(player: snapVideo)
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

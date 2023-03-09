//
//  VideoPreviewView.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/15.
//  Copyright © 2022 agora.io. All rights reserved.
//

import AVFoundation
import UIKit

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
}

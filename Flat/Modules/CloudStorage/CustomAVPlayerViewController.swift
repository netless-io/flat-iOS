//
//  CustomAVPlayerViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/23.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AVKit
import UIKit

class CustomAVPlayerViewController: AVPlayerViewController {
    var dismissHandler: (() -> Void)?

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismissHandler?()
    }
}

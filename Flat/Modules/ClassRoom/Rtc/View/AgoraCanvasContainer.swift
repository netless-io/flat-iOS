//
//  CV.swift
//  Flat
//
//  Created by xuyunshi on 2023/2/21.
//  Copyright © 2023 agora.io. All rights reserved.
//

import MetalKit
import UIKit

class AgoraCanvasContainer: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override var frame: CGRect {
        didSet {
            // Warning: update view's frame when the view is directly on the window hierachy will not trigger `layoutSubviews` function.
            subviews.forEach { $0.frame = bounds }
        }
    }
    
    var mtk: MTKView? { subviews.first?.subviews.first as? MTKView }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.frame = bounds }
        mtk?.framebufferOnly = false // To enable snapshot.
    }
    
    var fallbackSnapShot: CGImage?
    var storedSnapShot: CGImage? {
        didSet {
            if storedSnapShot != nil {
                fallbackSnapShot = storedSnapShot
            }
        }
    }

    func tryUpdateSnpaShot() {
        storedSnapShot = nil
        endSnapShot()
        startSnapShot()
    }
    
    var showSnapShot = false
    func displayLatestSnapShot(duration: TimeInterval) {
        if let storedSnapShot {
            layer.contents = storedSnapShot.resize(size: bounds.size)
        } else if let fallbackSnapShot {
            layer.contents = fallbackSnapShot.resize(size: bounds.size)
        }
        
        mtk?.isHidden = true
        showSnapShot = true
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(removeSnapShot), with: nil, afterDelay: duration)
    }
    
    @objc func removeSnapShot() {
        if showSnapShot {
            layer.contents = nil
            mtk?.isHidden = false
            showSnapShot = false
        }
    }
    
    @objc fileprivate func startSnapShot() {
        // TODO: Small frame snapShot for bigger  - -
        if let texture = mtk?.currentDrawable?.texture {
            if let snapShot = texture.toImage() {
                if !snapShot.isBlack {
                    // Resize img to fit size
                    storedSnapShot = snapShot.resize(size: bounds.size)
                    endSnapShot()
                    return
                }
            }
        }
        perform(#selector(startSnapShot), with: nil, afterDelay: 0.1)
    }
    
    fileprivate func endSnapShot() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    // Disable constraints to enable avoid wrong layout result.
    override func updateConstraints() {
        if !constraints.filter(\.isActive).isEmpty {
            constraints.forEach { $0.isActive = false }
        }
        super.updateConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

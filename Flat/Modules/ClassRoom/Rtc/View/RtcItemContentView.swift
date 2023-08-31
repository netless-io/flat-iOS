//
//  RtcItemContentView.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/9.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class RtcItemContentView: UIView {
    
    override var frame: CGRect {
        didSet {
            // Warning: update view's frame when the view is directly on the window hierachy will not trigger `layoutSubviews` function.
            self.videoContainerView.frame = self.bounds

            let micFrame = CGRect(x: bounds.width - micIconSize.width - 4,
                                  y: bounds.height - micIconSize.height - 4,
                                  width: micIconSize.width,
                                  height: micIconSize.height)
            micStrenthView.frame = micFrame
            silenceImageView.frame = micStrenthView.frame
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoContainerView.frame = bounds
        
        largeAvatarImageView.frame = bounds
        effectView.frame = bounds
        offlineMaskLabel.frame = bounds
        nameLabel.frame = .init(origin: .init(x: 4, y: bounds.height - 18),
                                size: .init(width: bounds.width - 44, height: 18))
        let avatarWidth = bounds.width * 48.0 / 112.0
        avatarImageView.bounds = .init(origin: .zero, size: .init(width: avatarWidth, height: avatarWidth))
        avatarImageView.center = .init(x: bounds.width / 2, y: bounds.height / 2)
        avatarImageView.layer.cornerRadius = avatarWidth / 2

        let micFrame = CGRect(x: bounds.width - micIconSize.width - 4,
                              y: bounds.height - micIconSize.height - 4,
                              width: micIconSize.width,
                              height: micIconSize.height)
        micStrenthView.frame = micFrame
        silenceImageView.frame = micStrenthView.frame
    }
    
    var showAvatar = false {
        didSet {
            updateDisplayStyle()
        }
    }
    
    var isDragging = false {
        didSet {
            updateDisplayStyle()
        }
    }
    
    var showVolume = false {
        didSet {
            updateDisplayStyle()
        }
    }
    
    func toggleControlViewDisplay() {
        if controlView.isHidden {
            showControlViewAndHideAfter(delay: 3)
        } else {
            controlView.isHidden = true
        }
    }
    
    func showControlViewAndHideAfter(delay: CGFloat) {
        controlView.isHidden = false
        Self.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(_delayHideFloat), with: self, afterDelay: delay)
    }
    
    @objc func _delayHideFloat() {
        controlView.isHidden = true
    }
    
    func updateDisplayStyle() {
        if showAvatar {
            largeAvatarImageView.isHidden = false
            effectView.isHidden = false
            avatarImageView.isHidden = false
            videoContainerView.isHidden = true
        } else {
            largeAvatarImageView.isHidden = true
            effectView.isHidden = true
            avatarImageView.isHidden = true
            videoContainerView.isHidden = false
        }
        
        if isDragging {
            nameLabel.isHidden = true
            micStrenthView.isHidden = true
            silenceImageView.isHidden = true
            controlView.isHidden = true
        } else {
            nameLabel.isHidden = false
            micStrenthView.isHidden = !showVolume
            silenceImageView.isHidden = showVolume
        }
    }
    
    let uid: UInt
    init(uid: UInt) {
        self.uid = uid
        super.init(frame: .zero)
        backgroundColor = .black
        clipsToBounds = true
        
        addSubview(videoContainerView)
        addSubview(largeAvatarImageView)
        addSubview(effectView)
        addSubview(avatarImageView)
        addSubview(silenceImageView)
        addSubview(offlineMaskLabel)
        addSubview(nameLabel)
        addSubview(micStrenthView)
        
        addSubview(controlView)
        controlView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(4)
        }
        controlView.isHidden = true
    }
    
    fileprivate var animationCompleteBlock: ((RtcItemContentView) -> Void)?
    
    let defaultAnimationkey = "k"
    // Set default to infinite as a default value to diff tiny change.
    var animationToFrame = CGRect.infinite
    func animation(x: CGFloat,
                   y: CGFloat,
                   xScale: CGFloat,
                   yScale: CGFloat,
                   animationDuration: TimeInterval,
                   completionBlock: ((RtcItemContentView) -> Void)? = nil)
    {
        if let _ = layer.animation(forKey: defaultAnimationkey) {
            layer.removeAnimation(forKey: defaultAnimationkey)
        }
        animationCompleteBlock = completionBlock
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = []

        let xAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        xAnimation.fromValue = 0
        xAnimation.toValue = x
        
        let yAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        yAnimation.fromValue = 0
        yAnimation.toValue = y
        
        let xScaleAnimation = CABasicAnimation(keyPath: "transform.scale.x")
        xScaleAnimation.fromValue = 1
        xScaleAnimation.toValue = xScale
        
        let yScaleAnimation = CABasicAnimation(keyPath: "transform.scale.y")
        yScaleAnimation.fromValue = 1
        yScaleAnimation.toValue = yScale
        
        animationGroup.animations = [xAnimation, yAnimation, xScaleAnimation, yScaleAnimation]
        animationGroup.duration = animationDuration
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = .forwards
        animationGroup.delegate = self
        layer.add(animationGroup, forKey: defaultAnimationkey)
    }
    
    func finishCurrentAnimation() {
        if let _ = layer.animation(forKey: defaultAnimationkey) {
            layer.removeAnimation(forKey: defaultAnimationkey)
            performAnimationCompleteBlock()
        }
    }
    
    fileprivate var canvasContainer: AgoraCanvasContainer? {
        videoContainerView.subviews.first as? AgoraCanvasContainer
    }
    
    func updateRtcSnapShot() {
        canvasContainer?.tryUpdateSnpaShot()
    }
    
    func endRtcSnapShot() {
        canvasContainer?.endSnapShot()
    }
    
    func tempDisplaySnapshot(duration: TimeInterval = 0.1) {
        canvasContainer?.displayLatestSnapShot(duration: duration)
    }
    
    var micStrenth: CGFloat = 0 {
        didSet {
            updateStrenth(micStrenth, oldStrenth: oldValue)
        }
    }

    // From 0-1
    fileprivate func updateStrenth(_ newStrenth: CGFloat, oldStrenth: CGFloat) {
        func pathFor(strens s: CGFloat) -> CGPath {
            let s = min(1, max(0, s))
            let offset: CGFloat = (1 - s) * micSize.height
            let path: CGPath = .init(rect: .init(x: micOrigin.x,
                                                 y: micOrigin.y + offset,
                                                 width: micSize.width,
                                                 height: micSize.height - offset),
                                     transform: nil)
            return path
        }

        let strengthAnimationKey = "strenthAnimation"
        if let _ = micStrenthMaskLayer.animation(forKey: strengthAnimationKey) {
            micStrenthMaskLayer.removeAnimation(forKey: strengthAnimationKey)
        }
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.5
        animation.fromValue = pathFor(strens: oldStrenth)
        animation.toValue = pathFor(strens: newStrenth)
        micStrenthMaskLayer.add(animation, forKey: strengthAnimationKey)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
    
    lazy var videoContainerView = RtcItemVideoContainer()
    
    lazy var largeAvatarImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    lazy var effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(frame: .init(origin: .zero, size: .init(width: 48, height: 48)))
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    lazy var silenceImageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .center
        view.layer.cornerRadius = micStrenthView.bounds.size.width / 2
        view.setTraitRelatedBlock { v in
            v.image = UIImage(named: "silence")?.tintColor(.color(type: .danger).resolvedColor(with: v.traitCollection))
        }
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()

    lazy var offlineMaskLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.isHidden = true
        label.backgroundColor = .black.withAlphaComponent(0.66)
        label.text = localizeStrings("offline")
        return label
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()

    let micOrigin: CGPoint = .init(x: 8, y: 4)
    let micSize: CGSize = .init(width: 8, height: 14)
    let micIconSize = CGSize(width: 24, height: 24)

    lazy var micStrenthView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "microphone_volume"))
        image.tintColor = .white
        image.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        image.frame = .init(origin: .zero, size: micIconSize)
        image.clipsToBounds = true
        image.layer.cornerRadius = 12
        DispatchQueue.main.async {
            image.layer.addSublayer(self.micStrenthLayer)
        }
        return image
    }()

    lazy var micStrenthLayer: CAShapeLayer = {
        let strenthLayer = CAShapeLayer()
        strenthLayer.frame = micStrenthView.bounds
        strenthLayer.path = .init(roundedRect: .init(origin: self.micOrigin, size: self.micSize), cornerWidth: 4, cornerHeight: 4, transform: nil)
        strenthLayer.fillColor = UIColor.systemGreen.cgColor
        strenthLayer.mask = self.micStrenthMaskLayer
        return strenthLayer
    }()

    lazy var micStrenthMaskLayer = CAShapeLayer()
    
    lazy var controlView = InnerPermissionControlView()
}

extension RtcItemContentView: CAAnimationDelegate {
    func performAnimationCompleteBlock() {
        animationCompleteBlock?(self)
        animationCompleteBlock = nil
    }
    
    func animationDidStart(_ anim: CAAnimation) {}
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            layer.removeAnimation(forKey: defaultAnimationkey)
            performAnimationCompleteBlock()
        }
    }
}

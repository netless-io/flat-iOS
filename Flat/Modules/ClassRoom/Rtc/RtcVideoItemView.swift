//
//  RtcVideoItemView.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RtcVideoItemView: UIView {
    var alwaysShowName = false {
        didSet {
            if alwaysShowName {
                nameLabel.isHidden = false
            }
        }
    }
    
    var tapHandler: ((RtcVideoItemView)->Void)?
    
    let uid: UInt

    @objc func onTap() {
        tapHandler?(self)
    }
    
    func showAvatar(_ show: Bool) {
        largeAvatarImageView.isHidden = !show
        effectView.isHidden = !show
        avatarImageView.isHidden = !show
    }
    
    func update(avatar: URL?) {
        largeAvatarImageView.kf.setImage(with: avatar)
        avatarImageView.kf.setImage(with: avatar)
    }
    
    func showMicVolum(_ show: Bool) {
        micStrenthView.isHidden = !show
    }
    
    var micStrenth: CGFloat = 0 {
        didSet {
            updateStrenth(micStrenth, oldStrenth: oldValue)
        }
    }
    
    /// From 0-1
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
        addSubview(nameLabel)
        addSubview(micStrenthView)
        micStrenthView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().inset(4)
            make.size.equalTo(micStrenthView.bounds.size)
        }
        avatarImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(self.snp.width).multipliedBy(48.0 / 112.0)
        }
        largeAvatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        silenceImageView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().inset(4)
        }
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoContainerView.frame = bounds
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }
    
    // MARK: - Lazy
    lazy var videoContainerView = UIView()
    
    lazy var largeAvatarImageView: UIImageView  = {
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
    
    lazy var silenceImageView = UIImageView(image: UIImage(named: "silence"))
    
    lazy var nameLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return label
    }()
    
    let micOrigin: CGPoint = .init(x: 8, y: 4)
    let micSize: CGSize = .init(width: 8, height: 14)
    
    lazy var micStrenthView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "microphone_volume"))
        image.tintColor = .white
        image.backgroundColor = UIColor.init(hexString: "#999CA3").withAlphaComponent(0.01)
        image.frame = .init(origin: .zero, size: .init(width: 24, height: 24))
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
}

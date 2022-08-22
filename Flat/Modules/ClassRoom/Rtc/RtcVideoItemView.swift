//
//  RtcVideoItemView.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RtcVideoItemView: UIView {
    var containsUserValue = false
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
    
    init(uid: UInt) {
        self.uid = uid
        super.init(frame: .zero)
        backgroundColor = .black
        clipsToBounds = true
        layer.cornerRadius = 4

        addSubview(videoContainerView)
        addSubview(largeAvatarImageView)
        addSubview(effectView)
        addSubview(avatarImageView)
        addSubview(silenceImageView)
        addSubview(nameLabel)
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
}

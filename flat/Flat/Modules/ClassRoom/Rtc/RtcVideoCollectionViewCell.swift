//
//  RtcVideoCollectionViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RtcVideoCollectionViewCell: UICollectionViewCell {
    func update(avatar: URL?) {
        largeAvatarImageView.kf.setImage(with: avatar)
        avatarImageView.kf.setImage(with: avatar)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        videoContainerView.subviews.forEach({ $0.removeFromSuperview() })
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        layer.cornerRadius = 4

        contentView.addSubview(videoContainerView)
        contentView.addSubview(largeAvatarImageView)
        contentView.addSubview(effectView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(silenceImageView)
        addSubview(nameLabel)
        avatarImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(contentView.snp.width).multipliedBy(48.0 / 112.0)
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoContainerView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

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
        view.layer.cornerRadius = 24
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

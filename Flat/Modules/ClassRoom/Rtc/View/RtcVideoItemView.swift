//
//  RtcVideoItemView.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class RtcVideoItemView: UIView {
    var tapHandler: ((RtcItemContentView) -> Void)?
    var doubleTapHandler: ((RtcItemContentView)->Void)?

    func update(avatar: URL?) {
        contentView.largeAvatarImageView.kf.setImage(with: avatar)
        contentView.avatarImageView.kf.setImage(with: avatar)
    }

    // MARK: - Action

    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        if gesture.numberOfTapsRequired == 1 {
            tapHandler?(contentView)
        } else {
            doubleTapHandler?(contentView)
        }
    }
    
    // MARK: - Private

    let uid: UInt
    init(uid: UInt) {
        self.uid = uid
        super.init(frame: .zero)
        backgroundColor = .color(light: .grey0, dark: .grey7)
        addSubview(backLabel)
        backLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        
        addSubview(contentView)
        
        contentView.addGestureRecognizer(tap)
        contentView.addGestureRecognizer(doubleTap)
        tap.delegate = self
    }

    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
    lazy var doubleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tap.numberOfTapsRequired = 2
        return tap
    }()
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if contentView.superview === self {
            contentView.frame = bounds
        }
    }

    // MARK: - Lazy
    lazy var contentView = RtcItemContentView(uid: uid)
    lazy var backLabel: UILabel = {
       let label = UILabel()
        label.textColor = .color(light: .grey3, dark: .grey5)
        return label
    }()
}

extension RtcVideoItemView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tap, otherGestureRecognizer == doubleTap { return true }
        return false
    }
}


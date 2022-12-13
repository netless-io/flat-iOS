//
//  UIView+Badge.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/9.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

private class BadgeView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .systemRed
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}

extension UIView {
    private func getBadageView() -> BadgeView {
        let badgeView: BadgeView
        if let view = subviews.first(where: { $0 is BadgeView }) as? BadgeView {
            badgeView = view
        } else {
            let view = BadgeView()
            addSubview(view)
            badgeView = view
        }
        return badgeView
    }

    func setupBadgeView(rightInset: CGFloat, topInset: CGFloat) {
        let view = getBadageView()
        view.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(rightInset)
            make.top.equalToSuperview().inset(topInset)
            make.width.height.equalTo(6)
        }
        view.isHidden = true
    }

    func updateBadgeHide(_ hide: Bool) {
        let view = getBadageView()
        view.isHidden = hide
    }
}

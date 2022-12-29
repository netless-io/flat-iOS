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
        addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
    
    lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        return label
    }()
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

    func setupBadgeView(rightInset: CGFloat, topInset: CGFloat, width: CGFloat = 6) {
        let view = getBadageView()
        view.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(rightInset)
            make.top.equalToSuperview().inset(topInset)
            make.width.height.equalTo(width)
        }
        view.isHidden = true
    }

    func updateBadgeHide(_ hide: Bool, count: Int = 0) {
        let view = getBadageView()
        view.isHidden = hide
        view.countLabel.text = count > 0 ? count.description : nil
    }
}

//
//  LoginBackgroundView.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/18.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class CompactLoginBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func syncTraitCollection() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        gradientLayer.isHidden = isDark
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        syncTraitCollection()
    }
    
    func setupViews() {
        backgroundColor = .clear
        layer.addSublayer(gradientLayer)
        addSubview(logoImageView)
        syncTraitCollection()
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(10)
        }
    }

    lazy var logoImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "login_compact_bg"))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hexString: "#69A0FF").cgColor,
            UIColor.white.cgColor,
        ]
        return layer
    }()
}

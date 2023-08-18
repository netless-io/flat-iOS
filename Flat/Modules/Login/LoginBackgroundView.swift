//
//  LoginBackgroundView.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/18.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class LoginBackgroundView: UIView {
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
        logoImageView.frame = bounds
        gradientLayer.frame = bounds
    }
    
    func updateGradientColor() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        if isDark {
            gradientLayer.colors = [
                UIColor(hexString: "#1756C3").cgColor,
                UIColor(hexString: "#00225E").cgColor,
            ]
        } else {
            gradientLayer.colors = [
                UIColor(hexString: "#69A0FF").cgColor,
                UIColor.white.cgColor,
            ]
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateGradientColor()
    }
    
    func setupViews() {
        layer.addSublayer(gradientLayer)
        addSubview(logoImageView)
        updateGradientColor()
    }

    lazy var logoImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "login_pad"))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        return layer
    }()
}

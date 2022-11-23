//
//  DashLineView.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/24.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class DashLineView: UIView {
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
        dashLineLayer.frame = bounds
        let path = CGMutablePath()
        path.addLines(between: [
            .init(x: 0, y: bounds.height / 2),
            .init(x: bounds.width, y: bounds.height / 2)
        ])
        dashLineLayer.path = path
    }
    
    func setupViews() {
        backgroundColor = .clear
        layer.addSublayer(dashLineLayer)
        dashLineLayer.strokeColor = UIColor(hexString: "#E5E8F0").cgColor
        dashLineLayer.lineWidth = commonBorderWidth
        dashLineLayer.lineJoin = .miter
        dashLineLayer.lineDashPattern = [2, 2]
    }
    
    lazy var dashLineLayer = CAShapeLayer()
}

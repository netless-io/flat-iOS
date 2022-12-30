//
//  UIView+DidLayoutBlock.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

public extension UIView {
    ///   - warning: 本方法对scrollview无效，请注意
    func setDidLayoutHandle(_ handler: @escaping ((CGRect) -> Void)) {
        for view in subviews {
            if let inter = view as? InterView {
                inter.didLayoutHandler = handler
                inter.setNeedsLayout()
                return
            }
        }
        let host = InterView(handler: handler)
        addSubview(host)
        host.isUserInteractionEnabled = false
        host.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

private class InterView: UIView {
    var didLayoutHandler: (CGRect) -> Void

    init(handler: @escaping ((CGRect) -> Void)) {
        didLayoutHandler = handler
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        didLayoutHandler(bounds)
    }
}

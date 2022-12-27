//
//  PopMenuView.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/3.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class PopMenuView: UIView {
    enum Direction {
        case top
        case left
        case bottom
        case right
    }

    var dismissHandle: (() -> Void)?
    weak var sourceView: UIView?

    func dismiss() {
        bg.removeFromSuperview()
        removeFromSuperview()
        dismissHandle?()
        sourceView = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            sourceView = nil
        }
    }

    @objc func onTapBg(_: UITapGestureRecognizer) {
        dismiss()
    }

    lazy var bg: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.03)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapBg(_:))))
        return view
    }()

    func show(fromSource source: UIView?,
              direction: Direction,
              inset: UIEdgeInsets)
    {
        if source == sourceView { return }
        sourceView = source
        guard let target = fetchKeyWindow() else { return }
        if superview == nil {
            target.addSubview(bg)
            target.addSubview(self)
            bg.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        let x: CGFloat
        let y: CGFloat
        if let source {
            let sOrigin = source.convert(CGPoint.zero, to: target)
            switch direction {
            case .left:
                x = sOrigin.x - intrinsicContentSize.width + inset.left
                y = sOrigin.y + inset.top - inset.bottom + ((source.bounds.height - intrinsicContentSize.height) / 2)
            case .right:
                x = sOrigin.x + source.bounds.width - inset.right
                y = sOrigin.y + inset.top - inset.bottom + ((source.bounds.height - intrinsicContentSize.height) / 2)
            case .top:
                y = sOrigin.y - intrinsicContentSize.height + inset.top
                x = sOrigin.x + inset.left - inset.right + ((source.bounds.width - intrinsicContentSize.width) / 2)
            case .bottom:
                y = sOrigin.y + source.bounds.height - inset.bottom
                x = sOrigin.x + inset.left - inset.right + ((source.bounds.width - intrinsicContentSize.width) / 2)
            }
        } else {
            x = (target.bounds.width - intrinsicContentSize.width) / 2
            y = (target.bounds.height - intrinsicContentSize.height) / 2
        }
        frame = .init(origin: .init(x: x, y: y), size: intrinsicContentSize)
    }
}

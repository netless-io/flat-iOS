//
//  RoomControlBar.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RoomControlBar: UIView {
    enum NarrowStyle {
        case none
        case narrowMoreThan(count: Int)
    }
    
    let direction: NSLayoutConstraint.Axis
    let borderMask: CACornerMask
    let narrowMoreThan: Int
    
    init(direction: NSLayoutConstraint.Axis,
         borderMask: CACornerMask,
         buttons: [UIButton],
         narrowStyle: NarrowStyle = .none) {
        self.direction = direction
        self.borderMask = borderMask
        switch narrowStyle {
        case .none:
            narrowMoreThan = 0
        case .narrowMoreThan(let count):
            narrowMoreThan = count
        }
        super.init(frame: .zero)
        //        let effect: UIBlurEffect
        //        if #available(iOS 13.0, *) {
        //            effect = .init(style: .systemMaterialLight)
        //        } else {
        //            effect = .init(style: .extraLight)
        //        }
        //        let effectView = UIVisualEffectView(effect: effect)
        //        addSubview(effectView)
        //        effectView.snp.makeConstraints { make in
        //            make.edges.equalToSuperview()
        //        }
        backgroundColor = .whiteBG
        
        clipsToBounds = true
        layer.maskedCorners = borderMask
        layer.cornerRadius = 10
        
        layer.borderColor =  UIColor.borderColor.cgColor
        layer.borderWidth = 1 / UIScreen.main.scale
        
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        buttons.forEach({
            stack.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize.init(width: 40, height: 40))
            }
        })
        if narrowMoreThan > 0 {
            stack.addArrangedSubview(foldButton)
            foldButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize.init(width: 40, height: 40))
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc func onClickScale(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let isNarrow = sender.isSelected
        if !isNarrow {
            stack.arrangedSubviews.forEach({ $0.isHidden = false })
        } else {
            let itemCount = stack.arrangedSubviews.count
            stack.arrangedSubviews.enumerated().forEach { i in
                if i.offset == itemCount - 1 {
                    i.element.isHidden = false
                    return
                }
                i.element.isHidden = i.offset >= narrowMoreThan
            }
        }
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        stack.axis = direction
        stack.spacing = 0
        return stack
    }()
    
    lazy var foldButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(onClickScale), for: .touchUpInside)
        btn.setImage(UIImage(named: "small_arr_down")?.tintColor(.controlNormal), for: .selected) // narrow
        btn.setImage(UIImage(named: "small_arr_top")?.tintColor(.controlNormal), for: .normal) // expand
        return btn
    }()
}


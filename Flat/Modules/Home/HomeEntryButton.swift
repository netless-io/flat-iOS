//
//  HomeEntryButton.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/30.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class HomeEntryButton: UIView {
    init(imageName: String, title: String) {
        imageView = UIImageView()
        imageView.setDynamicImage(dynamicName: imageName)
        imageView.contentMode = .scaleAspectFit
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .text
        label.textAlignment = .center
        label.text = title
        super.init(frame: .zero)
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(label)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    lazy var animator: UIViewPropertyAnimator = {
        let ani = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
            let scale: CGFloat = 0.85
            self.stack.transform = .init(scaleX: scale, y: scale)
        }
        ani.pausesOnCompletion = true
        return ani
    }()
    
    var touchesBeginDate: Date = Date()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touchesBeginDate = Date()
        animator.startAnimation()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        breakAnimation(fireAction: false)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let isEndInView = touches.allSatisfy({
            let location = $0.location(in: self)
            return self.bounds.contains(location)
        })
        if isEndInView {
            breakAnimation(fireAction: true)
        } else {
            breakAnimation(fireAction: false)
        }
    }
    
    func breakAnimation(fireAction: Bool) {
        
        if fireAction {
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            if let t = target, let s = sel {
                _ = t.perform(s)
            }
        }
        
        let interval = Date().timeIntervalSince(touchesBeginDate)
        animator.fractionComplete = 0
        animator.pauseAnimation()
        if interval <= 0.05 {
            let basic = CABasicAnimation(keyPath: "transform.scale")
            basic.isRemovedOnCompletion = true
            basic.duration = 0.15
            basic.fromValue = 1
            basic.toValue = 0.9
            stack.layer.add(basic, forKey: "short_animation")
        }
    }
    
    weak var target: AnyObject?
    var sel: Selector?
    func addTarget(_ target: Any?, action: Selector) {
        self.target = target as? AnyObject
        self.sel = action
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageView: UIImageView
    
    lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()
}

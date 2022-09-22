//
//  SpringButton.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/22.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class SpringButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsImageWhenHighlighted = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    lazy var animator: UIViewPropertyAnimator = {
        let ani = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 10) {
            let scale: CGFloat = 0.98
            self.transform = .init(scaleX: scale, y: scale)
        }
        ani.pausesOnCompletion = true
        return ani
    }()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animator.isReversed = false
        animator.startAnimation()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let isMoveInView = touches.allSatisfy({
            let location = $0.location(in: self)
            return self.bounds.contains(location)
        })
        
        if !isMoveInView, !animator.isReversed {
            animator.isReversed = true
            animator.startAnimation()
        } else if isMoveInView, animator.isReversed {
            animator.isReversed = false
            animator.startAnimation()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animator.isReversed = false
        animator.pauseAnimation()
        animator.fractionComplete = 0
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animator.isReversed = false
        animator.pauseAnimation()
        animator.fractionComplete = 0
    }
}

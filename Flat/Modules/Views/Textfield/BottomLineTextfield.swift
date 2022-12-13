//
//  BottomLineTextfield.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/24.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

class BottomLineTextfield: UITextField {
    let shadowHeight: CGFloat = 2
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
        let height: CGFloat = commonBorderWidth
        line.frame = .init(origin: .init(x: 0, y: bounds.size.height - height), size: .init(width: bounds.width, height: height))
    }

    func setupViews() {
        addSubview(line)

        rx.editing
            .drive(with: self, onNext: { weakSelf, edit in
                weakSelf.setLineSelected(edit)
            })
            .disposed(by: rx.disposeBag)
    }

    func setLineSelected(_ selected: Bool) {
        let color = selected ? UIColor.color(type: .primary) : UIColor.borderColor
        UIView.animate(withDuration: 0.15) {
            self.line.backgroundColor = color
            if selected {
                self.line.layer.shadowColor = UIColor.color(type: .primary).cgColor
                self.line.layer.shadowOpacity = 0.3
                self.line.layer.shadowOffset = .init(width: 0, height: 2)
                self.line.layer.shadowRadius = 4
            } else {
                self.line.layer.shadowColor = UIColor.clear.cgColor
            }
        }
    }

    var line: UIView = {
        let view = UIView()
        view.backgroundColor = .borderColor
        return view
    }()
}

//
//  FlatPopoverAlertController.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/29.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit


class FlatPopoverAlertController: UIViewController {
    var actions: [Action]
    
    init(_ actions: [Action]) {
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addAction(_ action: Action) {
        self.actions.append(action)
    }
    
    let rowHeight: CGFloat = 40
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        let itemsHeight = CGFloat(stack.arrangedSubviews.count) * rowHeight
        preferredContentSize = .init(width: 160, height: itemsHeight)
    }
    
    @objc func onClickAction(button: UIButton) {
        let action = actions[button.tag]
        if action.isCancelAction() {
            dismissView()
            return
        }
        dismiss(animated: true) {
            action.handler?(action)
        }
    }
    
    func dismissView() {
        dismiss(animated: true)
    }
    
    func setupViews() {
        view.backgroundColor = .customAlertBg
        let buttons = actions.enumerated().compactMap { value -> UIButton? in
            if value.element.isCancelAction() { return nil }
            let title = value.element.title
            let btn = UIButton(type: .custom)
            btn.setTitle(title, for: .normal)
            btn.contentHorizontalAlignment = .left
            btn.tag = value.offset
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
            btn.titleLabel?.font = .systemFont(ofSize: 14)
            if value.element.style == .destructive {
                btn.setTitleColor(.color(type: .danger), for: .normal)
                btn.traitCollectionUpdateHandler = { [weak btn] _ in
                    btn?.setTitleColor(.color(type: .danger), for: .normal)
                }
            } else {
                btn.setTitleColor(.color(type: .text), for: .normal)
                btn.traitCollectionUpdateHandler = { [weak btn] _ in
                    btn?.setTitleColor(.color(type: .text), for: .normal)
                }
            }
            btn.addTarget(self, action: #selector(onClickAction(button:)), for: .touchUpInside)
            return btn
        }
        buttons.forEach { stack.addArrangedSubview($0) }
        view.addSubview(stack)
        
        stack.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(CGFloat(stack.arrangedSubviews.count) * rowHeight)
        }
    }
    
    lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.backgroundColor = .customAlertBg
        return stack
    }()
}

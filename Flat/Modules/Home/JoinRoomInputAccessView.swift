//
//  JoinRoomInputAccessView.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/19.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class JoinRoomInputAccessView: UIView {
    var enterHandler: ((UIButton) -> Void)?

    var cameraOn: Bool {
        didSet {
            deviceStateView.set(cameraOn: cameraOn)
        }
    }

    var micOn: Bool {
        didSet {
            deviceStateView.set(micOn: micOn)
        }
    }

    var enterEnable: Bool = false {
        didSet {
            joinButton.isEnabled = enterEnable
        }
    }

    init(cameraOn: Bool, micOn: Bool, enterTitle: String) {
        self.cameraOn = cameraOn
        self.micOn = micOn
        deviceStateView = CameraMicToggleView(cameraOn: cameraOn, micOn: micOn)
        super.init(frame: .init(x: 0, y: 0, width: 0, height: 44))
        joinButton.setTitle(enterTitle, for: .normal)
        setupViews()
        hero.isEnabled = true
        hero.isEnabledForSubviews = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = .color(type: .background, .weak)
        addSubview(deviceStateView)
        deviceStateView.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
        }
        addSubview(joinButton)
        joinButton.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview().inset(4)
        }
    }

    @objc func onClickEnter(_ sender: UIButton) {
        enterHandler?(sender)
    }

    var deviceStateView: CameraMicToggleView

    lazy var joinButton: UIButton = {
        let btn = FlatGeneralCrossButton(type: .custom)
        btn.addTarget(self, action: #selector(onClickEnter(_:)), for: .touchUpInside)
        return btn
    }()
}

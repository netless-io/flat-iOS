//
//  RoomUserTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

private let mainContentTag = 1
private let emptyContentTag = 2
class RoomUserTableViewCell: UITableViewCell {
    enum OperationType {
        case camera
        case mic
        case onStage
        case whiteboard
        case raiseHand
    }

    var clickHandler: ((OperationType) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func set(operationType: OperationType, empty: Bool) {
        var container: UIView?
        switch operationType {
        case .camera:
            container = cameraButton.superview
        case .mic:
            container = micButton.superview
        case .onStage:
            container = onStageSwitch.superview
        case .whiteboard:
            container = whiteboardSwitch.superview
        case .raiseHand:
            container = raiseHandButton.superview
        }
        container?.viewWithTag(mainContentTag)?.isHidden = empty
        container?.viewWithTag(emptyContentTag)?.isHidden = !empty
    }
    
    func setupViews() {
        contentView.backgroundColor = .classroomChildBG
        contentView.addSubview(mainStackView)
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addLine(direction: .bottom, color: .classroomBorderColor, inset: .init(top: 0, left: 16, bottom: 0, right: 16))
        contentView.addSubview(userSelfPointer)
        userSelfPointer.snp.makeConstraints { make in
            make.centerX.equalTo(8)
            make.width.height.equalTo(4)
            make.centerY.equalToSuperview()
        }
    }
    
    func wrapView(_ v: UIView, spacing: CGFloat) -> UIView {
        let view = UIView()
        view.addSubview(v)
        v.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(spacing)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.right.equalToSuperview().priority(.low.advanced(by: -1))
        }
        v.tag = mainContentTag
        let emptyView = UILabel()
        emptyView.textColor = .color(type: .text, .weak)
        emptyView.text = "--"
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        emptyView.isHidden = true
        emptyView.tag = emptyContentTag
        return view
    }
    
    // MARK: - Action
    @objc func onClickCamera() {
        clickHandler?(.camera)
    }

    @objc func onClickMic() {
        clickHandler?(.mic)
    }

    @objc func onClickRaiseHand() {
        clickHandler?(.raiseHand)
    }
    
    @objc func onWhiteboardChanged() {
        clickHandler?(.whiteboard)
    }
    
    @objc func onStageChanged() {
        clickHandler?(.onStage)
    }

    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.textColor = .color(type: .text)
        return nameLabel
    }()

    lazy var statusLabel: UILabel = {
        let statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.text = "(\(localizeStrings("offline")))"
        statusLabel.textColor = .systemRed
        return statusLabel
    }()

    lazy var raiseHandButton: UIButton = {
        let raiseHandButton = UIButton(type: .custom)
        raiseHandButton.setTraitRelatedBlock { btn in
            raiseHandButton.setImage(UIImage(named: "raisehand_small_icon")?.tintColor(.color(type: .primary)), for: .normal)
            raiseHandButton.setImage(UIImage(named: "raisehand_small_icon")?.tintColor(UIColor.color(light: .grey3, dark: .grey6)), for: .disabled)
        }
        raiseHandButton.addTarget(self, action: #selector(onClickRaiseHand), for: .touchUpInside)
        raiseHandButton.tintColor = .color(type: .primary)
        raiseHandButton.contentEdgeInsets = .init(top: 8, left: 4, bottom: 8, right: 4)
        return raiseHandButton
    }()

    func updateCamera(on: Bool, enable: Bool) {
        let image = UIImage(named: on ? "camera_on" : "camera_off")
        let btnColor: UIColor
        switch (on, enable) {
        case (let isOn, true):
            btnColor = isOn ? .color(type: .primary) : .color(type: .danger)
        case (_, false):
            btnColor = .color(light: .grey3, dark: .grey6)
        }
        cameraButton.isUserInteractionEnabled = enable
        cameraButton.setTraitRelatedBlock { btn in
            btn.setImage(image?.tintColor(btnColor), for: .normal)
            btn.viewWithTag(222)?.layer.borderColor = UIColor.color(light: .grey3, dark: .grey6).cgColor
        }
    }
    func updateMic(on: Bool, enable: Bool) {
        let image = UIImage(named: on ? "mic_on" : "mic_off")
        let btnColor: UIColor
        switch (on, enable) {
        case (let isOn, true):
            btnColor = isOn ? .color(type: .primary) : .color(type: .danger)
        case (_, false):
            btnColor = .color(light: .grey3, dark: .grey6)
        }
        micButton.isUserInteractionEnabled = enable
        micButton.setTraitRelatedBlock { btn in
            btn.setImage(image?.tintColor(btnColor), for: .normal)
            btn.viewWithTag(222)?.layer.borderColor = UIColor.color(light: .grey3, dark: .grey6).cgColor
        }
    }
    
    func addRoundBorder(to view: UIView, tag: Int = 222) {
        let borderView = UIView()
        borderView.layer.borderWidth = commonBorderWidth
        borderView.layer.cornerRadius = 8
        borderView.clipsToBounds = true
        borderView.isUserInteractionEnabled = false
        borderView.tag = tag
        view.addSubview(borderView)
        borderView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.center.equalToSuperview()
        }
    }
    
    private lazy var cameraButton: UIButton = {
        let cameraButton = UIButton(type: .custom)
        cameraButton.addTarget(self, action: #selector(onClickCamera), for: .touchUpInside)
        cameraButton.contentEdgeInsets = .init(top: 8, left: 20, bottom: 8, right: 20)
        addRoundBorder(to: cameraButton)
        return cameraButton
    }()

    private lazy var micButton: UIButton = {
        let micButton = UIButton(type: .custom)
        micButton.addTarget(self, action: #selector(onClickMic), for: .touchUpInside)
        micButton.contentEdgeInsets = .init(top: 8, left: 20, bottom: 8, right: 20)
        addRoundBorder(to: micButton)
        return micButton
    }()

    lazy var userInfoStackView: UIStackView = {
        let nameStack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        nameStack.axis = .vertical
        nameStack.distribution = .fill
        nameStack.spacing = 2
        let view = UIStackView(arrangedSubviews: [avatarImageView, nameStack])
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .fill
        view.alignment = .center
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return view
    }()
    
    lazy var onStageContainer: UIView = {
        let view = UIView()
        view.addSubview(onStageSwitch)
        onStageSwitch.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        let btn = UIButton()
        view.addSubview(btn)
        btn.snp.makeConstraints {
            $0.center.equalTo(onStageSwitch).priority(.low)
            $0.width.height.equalTo(44)
        }
        btn.addTarget(self, action: #selector(onStageChanged), for: .touchUpInside)
        return view
    }()
    
    lazy var whiteboardContainer: UIView = {
        let view = UIView()
        view.addSubview(whiteboardSwitch)
        whiteboardSwitch.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        let btn = UIButton()
        view.addSubview(btn)
        btn.snp.makeConstraints {
            $0.center.equalTo(whiteboardSwitch).priority(.low)
            $0.width.height.equalTo(44)
        }
        btn.addTarget(self, action: #selector(onWhiteboardChanged), for: .touchUpInside)
        return view
    }()
    
    lazy var onStageSwitch: UISwitch = {
        let s = UISwitch()
        s.isUserInteractionEnabled = false
        return s
    }()
    
    lazy var whiteboardSwitch: UISwitch = {
        let s = UISwitch()
        s.isUserInteractionEnabled = false
        return s
    }()
    
    lazy var mainStackView: UIStackView = {
        let views = [userInfoStackView,
                     onStageContainer,
                     whiteboardContainer,
                     cameraButton,
                     micButton,
                     raiseHandButton]
        let wrappedViews = views.enumerated().map { (index, v) -> UIView in
            if v === cameraButton || v === micButton {
                return wrapView(v, spacing: 0)
            }
            return wrapView(v, spacing: 16)
        }
        let view = UIStackView(arrangedSubviews: wrappedViews)
        view.axis = .horizontal
        view.distribution = .fillProportionally
        wrappedViews.enumerated().forEach { (index, v) in
            v.snp.makeConstraints { make in
                make.height.equalToSuperview()
                make.width.equalTo(index == 0 ? classRoomUserNameWidth : classRoomNormalItemWidth).priority(.required)
            }
        }
        return view
    }()

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        return view
    }()
    
    lazy var userSelfPointer: UIView = {
        let view = UIView()
        view.backgroundColor = .color(type: .primary)
        view.clipsToBounds = true
        view.layer.cornerRadius = 2
        return view
    }()
}

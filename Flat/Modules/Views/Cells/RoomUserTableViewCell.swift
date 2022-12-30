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
        contentView.addLine(direction: .bottom, color: .borderColor, inset: .init(top: 0, left: 16, bottom: 0, right: 16))
        contentView.addSubview(userSelfPointer)
        userSelfPointer.snp.makeConstraints { make in
            make.centerX.equalTo(8)
            make.width.height.equalTo(4)
            make.centerY.equalToSuperview()
        }
    }
    
    func wrapView(_ v: UIView) -> UIView {
        let view = UIView()
        view.addSubview(v)
        v.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        v.tag = mainContentTag
        let emptyView = UILabel()
        emptyView.textColor = .color(type: .text, .weak)
        emptyView.text = "- / -"
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
        return statusLabel
    }()

    lazy var raiseHandButton: UIButton = {
        let raiseHandButton = UIButton(type: .custom)
        raiseHandButton.setImage(UIImage(named: "raisehand_small_icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        raiseHandButton.addTarget(self, action: #selector(onClickRaiseHand), for: .touchUpInside)
        raiseHandButton.tintColor = .color(type: .primary)
        raiseHandButton.contentEdgeInsets = .init(top: 8, left: 4, bottom: 8, right: 4)
        return raiseHandButton
    }()

    lazy var cameraButton: UIButton = {
        let cameraButton = UIButton(type: .custom)
        cameraButton.setTraitRelatedBlock { btn in
            btn.setImage(UIImage(named: "camera_off")?.tintColor(.color(type: .danger).resolvedColor(with: btn.traitCollection)), for: .normal)
            btn.setImage(UIImage(named: "camera_on")?.tintColor(.color(type: .primary).resolvedColor(with: btn.traitCollection)), for: .selected)
        }
        cameraButton.addTarget(self, action: #selector(onClickCamera), for: .touchUpInside)
        cameraButton.contentEdgeInsets = .init(top: 8, left: 4, bottom: 8, right: 4)
        return cameraButton
    }()

    lazy var micButton: UIButton = {
        let micButton = UIButton(type: .custom)
        micButton.setTraitRelatedBlock { btn in
            btn.setImage(UIImage(named: "mic_off")?.tintColor(.color(type: .danger).resolvedColor(with: btn.traitCollection)), for: .normal)
            btn.setImage(UIImage(named: "mic_on")?.tintColor(.color(type: .primary).resolvedColor(with: btn.traitCollection)), for: .selected)
        }
        micButton.addTarget(self, action: #selector(onClickMic), for: .touchUpInside)
        micButton.contentEdgeInsets = .init(top: 8, left: 4, bottom: 8, right: 4)
        return micButton
    }()

    lazy var userInfoStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [avatarImageView, nameLabel, statusLabel])
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .fill
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return view
    }()
    
    lazy var onStageContainer: UIView = {
        let view = UIView()
        view.addSubview(onStageSwitch)
        onStageSwitch.snp.makeConstraints { $0.edges.equalToSuperview() }
        let btn = UIButton()
        view.addSubview(btn)
        btn.snp.makeConstraints { $0.edges.equalToSuperview() }
        btn.addTarget(self, action: #selector(onStageChanged), for: .touchUpInside)
        return view
    }()
    
    lazy var whiteboardContainer: UIView = {
        let view = UIView()
        view.addSubview(whiteboardSwitch)
        whiteboardSwitch.snp.makeConstraints { $0.edges.equalToSuperview() }
        let btn = UIButton()
        view.addSubview(btn)
        btn.snp.makeConstraints { $0.edges.equalToSuperview() }
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
        let views = [userInfoStackView, onStageContainer, whiteboardContainer, cameraButton, micButton, raiseHandButton]
        let wrappedViews = views.map { wrapView($0) }
        let view = UIStackView(arrangedSubviews: wrappedViews)
        view.axis = .horizontal
        view.distribution = .fillEqually
        wrappedViews.forEach { v in
            v.snp.makeConstraints { make in
                make.height.equalToSuperview()
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

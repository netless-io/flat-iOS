//
//  ClassRoomSettingViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxCocoa
import RxRelay
import RxSwift
import UIKit

let classroomSettingNeedToggleCameraNotification = Notification.Name("classroomSettingNeedToggleCameraNotification")
class ClassRoomSettingViewController: UIViewController {
    enum SettingControlType {
        case camera
        case cameraDirection
        case mic
        case videoArea
        case shortcut

        var description: String {
            switch self {
            case.cameraDirection:
                return localizeStrings("CameraDirection")
            case .camera:
                return localizeStrings("Camera")
            case .mic:
                return localizeStrings("Mic")
            case .videoArea:
                return localizeStrings("Video Area")
            case .shortcut:
                return localizeStrings("Shortcuts")
            }
        }
    }

    let cameraPublish: PublishRelay<Void> = .init()
    let micPublish: PublishRelay<Void> = .init()
    let videoAreaPublish: PublishRelay<Void> = .init()
    var shortcutsPublish: PublishRelay<Void> = .init()

    let cellIdentifier = "cellIdentifier"

    let deviceUpdateEnable: BehaviorRelay<Bool>
    let cameraOn: BehaviorRelay<Bool>
    let micOn: BehaviorRelay<Bool>
    let videoAreaOn: BehaviorRelay<Bool>
    var models: [SettingControlType] = []
    var isCameraFront = true {
        didSet {
            tableView.reloadData()
            NotificationCenter.default.post(.init(name: classroomSettingNeedToggleCameraNotification))
        }
    }
    
    func reloadModels() {
        if cameraOn.value {
            models = [.shortcut, .camera, .cameraDirection, .mic, .videoArea]
        } else {
            models = [.shortcut, .camera, .mic, .videoArea]
        }
        tableView.reloadData()
    }

    // MARK: - LifeCycle

    init(cameraOn: Bool,
         micOn: Bool,
         videoAreaOn: Bool,
         deviceUpdateEnable: Bool)
    {
        self.cameraOn = .init(value: cameraOn)
        self.micOn = .init(value: micOn)
        self.videoAreaOn = .init(value: videoAreaOn)
        self.deviceUpdateEnable = .init(value: deviceUpdateEnable)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
        preferredContentSize = .init(width: 320, height: 480)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()

        Observable.of(cameraOn, micOn, videoAreaOn)
            .merge()
            .subscribe(with: self) { weakSelf, _ in
                weakSelf.reloadModels()
            }
            .disposed(by: rx.disposeBag)
    }

    // MARK: - Private

    func setupViews() {
        view.backgroundColor = .classroomChildBG
        view.addSubview(tableView)
        view.addSubview(topView)
        let topViewHeight: CGFloat = 40
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(topViewHeight)
        }

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: topViewHeight, left: 0, bottom: 0, right: 0))
        }

        let logoutHeight = CGFloat(40)
        let margin = CGFloat(14)
        let containerHeight = CGFloat(logoutHeight + margin + 30 + view.safeAreaInsets.bottom)
        let bottomContainer = UIView(frame: .init(origin: .zero, size: .init(width: 400, height: containerHeight)))
        bottomContainer.backgroundColor = .classroomChildBG
        tableView.contentInset = .init(top: 0, left: 0, bottom: containerHeight, right: 0)
        bottomContainer.addSubview(logoutButton)
        view.addSubview(bottomContainer)
        bottomContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: 400, height: containerHeight))
        }
        logoutButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(logoutHeight)
            make.top.equalToSuperview().inset(margin)
        }
    }

    func config(cell: ClassRoomSettingTableViewCell, type: SettingControlType) {
        cell.label.text = type.description
        cell.selectionStyle = .none
        cell.switch.isHidden = false
        cell.rightArrowImageView.isHidden = true
        cell.cameraToggleView.isHidden = true
        switch type {
        case .cameraDirection:
            cell.switch.isHidden = true
            cell.iconView.image = nil
            cell.cameraToggleView.isHidden = false
            cell.cameraToggleView.selectedSegmentIndex = isCameraFront ? 0 : 1
            cell.cameraFaceFrontChangedHandler = { [weak self] _ in
                self?.isCameraFront.toggle()
            }
        case .shortcut:
            cell.switch.isHidden = true
            cell.rightArrowImageView.isHidden = false
            cell.setEnable(true)
            cell.iconView.image = UIImage(named: "command")?.tintColor(.color(type: .text))
        case .camera:
            if cell.switch.isOn != cameraOn.value {
                cell.switch.isOn = cameraOn.value
            }
            cell.iconView.image = UIImage(named: "camera")?.tintColor(.color(type: .text))
            cell.setEnable(deviceUpdateEnable.value)
            cell.switchValueChangedHandler = { [weak self] _ in
                self?.cameraPublish.accept(())
            }
        case .mic:
            if cell.switch.isOn != micOn.value {
                cell.switch.isOn = micOn.value
            }
            cell.setEnable(deviceUpdateEnable.value)
            cell.switchValueChangedHandler = { [weak self] _ in
                self?.micPublish.accept(())
            }
            cell.iconView.image = UIImage(named: "microphone")?.tintColor(.color(type: .text))
        case .videoArea:
            cell.setEnable(true)
            cell.switch.isOn = videoAreaOn.value
            cell.switchValueChangedHandler = { [weak self] _ in
                self?.videoAreaPublish.accept(())
            }
            cell.iconView.image = UIImage(named: "video_area")?.tintColor(.color(type: .text))
        }
    }

    // MARK: - Lazy

    lazy var logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .classroomChildBG
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTraitRelatedBlock { button in
            let color = UIColor.color(light: .red6, dark: .red5)
            button.setTitleColor(color.resolvedColor(with: button.traitCollection), for: .normal)
            button.setImage(UIImage(named: "logout")?.tintColor(color.resolvedColor(with: button.traitCollection)), for: .normal)
            button.layer.borderColor = color.resolvedColor(with: button.traitCollection).cgColor
        }
        button.layer.borderWidth = commonBorderWidth
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.contentEdgeInsets = .init(top: 0, left: 20, bottom: 0, right: 20)
        button.setTitle(localizeStrings("Leaving Classroom"), for: .normal)
        return button
    }()

    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .classroomChildBG

        let leftIcon = UIImageView()
        view.setTraitRelatedBlock { [weak leftIcon] v in
            leftIcon?.image = UIImage(named: "classroom_setting")?.tintColor(.color(type: .text, .strong).resolvedColor(with: v.traitCollection))
        }
        leftIcon.contentMode = .scaleAspectFit
        view.addSubview(leftIcon)
        leftIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(8)
        }

        let topLabel = UILabel(frame: .zero)
        topLabel.text = localizeStrings("Setting")
        topLabel.textColor = .color(type: .text, .strong)
        topLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(40)
        }
        view.addLine(direction: .bottom, color: .borderColor)
        return view
    }()

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .classroomChildBG
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(.init(nibName: String(describing: ClassRoomSettingTableViewCell.self), bundle: nil), forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.rowHeight = 48
        view.showsVerticalScrollIndicator = false
        return view
    }()
}

extension ClassRoomSettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ClassRoomSettingTableViewCell
        let type = models[indexPath.row]
        config(cell: cell, type: type)
        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        models.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if models[indexPath.row] == .shortcut {
            shortcutsPublish.accept(())
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

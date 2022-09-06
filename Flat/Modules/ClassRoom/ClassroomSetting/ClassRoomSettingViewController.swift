//
//  ClassRoomSettingViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

class ClassRoomSettingViewController: UIViewController {
    enum SettingControlType {
        case camera
        case mic
        case videoArea
        
        var description: String {
            switch self {
            case .camera:
                return NSLocalizedString("Camera", comment: "")
            case .mic:
                return NSLocalizedString("Mic", comment: "")
            case .videoArea:
                return NSLocalizedString("Video Area", comment: "")
            }
        }
    }
    let cameraPublish: PublishRelay<Void> = .init()
    let micPublish: PublishRelay<Void> = .init()
    let videoAreaPublish: PublishRelay<Void> = .init()
    
    let cellIdentifier = "cellIdentifier"
    
    let deviceUpdateEnable: BehaviorRelay<Bool>
    let cameraOn: BehaviorRelay<Bool>
    let micOn: BehaviorRelay<Bool>
    let videoAreaOn: BehaviorRelay<Bool>
    
    var models: [SettingControlType] = [.camera, .mic, .videoArea]
    
    // MARK: - LifeCycle
    init(cameraOn: Bool,
         micOn: Bool,
         videoAreaOn: Bool,
         deviceUpdateEnable: Bool) {
        self.cameraOn = .init(value: cameraOn)
        self.micOn = .init(value: micOn)
        self.videoAreaOn = .init(value: videoAreaOn)
        self.deviceUpdateEnable = .init(value: deviceUpdateEnable)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        Observable.of(cameraOn, micOn, videoAreaOn)
            .merge()
            .subscribe(with: self) { weakSelf, _ in
                weakSelf.tableView.reloadData()
            }
            .disposed(by: rx.disposeBag)

        
        logoutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
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
            make.edges.equalToSuperview().inset(UIEdgeInsets.init(top: topViewHeight, left: 0, bottom: 0, right: 0))
        }
        
        let bottomContainer = UIView(frame: .init(origin: .zero, size: .init(width: 400, height: 96)))
        bottomContainer.addSubview(logoutButton)
        view.addSubview(bottomContainer)
        bottomContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.size.equalTo(CGSize(width: 400, height: 96))
        }
        logoutButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
        }
        
        preferredContentSize = .init(width: 320, height: 480)
    }
    
    func config(cell: ClassRoomSettingTableViewCell, type: SettingControlType) {
        cell.label.text = type.description
        cell.selectionStyle = .none
        switch type {
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
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.color(type: .danger), for: .normal)
        button.setImage(UIImage(named: "logout")?.tintColor(.color(type: .danger)), for: .normal)
        button.layer.borderColor = UIColor.color(type: .danger).cgColor
        button.traitCollectionUpdateHandler = { [weak button] _ in
            button?.setTitleColor(.color(type: .danger), for: .normal)
            button?.setImage(UIImage(named: "logout")?.tintColor(.color(type: .danger)), for: .normal)
            button?.layer.borderColor = UIColor.color(type: .danger).cgColor
        }
        
        button.layer.borderWidth = 1 / UIScreen.main.scale
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.contentEdgeInsets = .init(top: 0, left: 20, bottom: 0, right: 20)
        button.setTitle(NSLocalizedString("Leaving Classroom", comment: ""), for: .normal)
        return button
    }()
    
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .classroomChildBG
        
        let leftIcon = UIImageView(image: UIImage(named: "classroom_setting")?.tintColor(.color(type: .text, .stronger)))
        view.traitCollectionUpdateHandler = { [weak leftIcon] _ in
            leftIcon?.image = UIImage(named: "classroom_setting")?.tintColor(.color(type: .text, .stronger))
        }
        leftIcon.contentMode = .center
        view.addSubview(leftIcon)
        leftIcon.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(40)
        }
        
        let topLabel = UILabel(frame: .zero)
        topLabel.text = localizeStrings("Setting")
        topLabel.textColor = .color(type: .text, .stronger)
        topLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(40)
        }
        let line = UIView()
        line.backgroundColor = .borderColor
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1/UIScreen.main.scale)
        }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        models.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

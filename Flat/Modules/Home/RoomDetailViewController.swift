//
//  RoomDetailViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class RoomDetailViewController: UIViewController {
    var info: RoomBasicInfo?
    var hideAllActions = false

    func updateStatus(_ status: RoomStartStatus) {
        info?.roomStatus = status
        if isViewLoaded {
            updateEnterRoomButtonTitle()
        }
    }

    func updateInfo(_ info: RoomBasicInfo) {
        self.info = info
        if isViewLoaded {
            applyCurrentInfoToView()
        }
    }

    func applyCurrentInfoToView() {
        updateViewWithCurrentStatus()
        updateAvailableActions()
        updateEnterRoomButtonTitle()
    }

    // MARK: - LifeCycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyCurrentInfoToView()
        loadData { [weak self] _ in
            guard let self else { return }
            self.applyCurrentInfoToView()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mainStackView.axis = view.bounds.width <= 428 ? .vertical : .horizontal
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        observeRoomRemoved()
    }

    // MARK: - Private

    func loadData(completion: @escaping ((Result<RoomBasicInfo, Error>) -> Void)) {
        guard let fetchingInfo = info else { return }
        RoomBasicInfo.fetchInfoBy(uuid: fetchingInfo.roomUUID, periodicUUID: fetchingInfo.periodicUUID) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(detail):
                if self.info?.roomUUID == detail.roomUUID {
                    self.info = detail
                    completion(.success(detail))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    @objc func onRoomRemoved(_ notification: Notification) {
        guard
            let roomUUID = notification.userInfo?["roomUUID"] as? String,
            roomUUID == info?.roomUUID
        else { return }
        mainContainer?.removeTop()
    }

    func observeRoomRemoved() {
        NotificationCenter.default.addObserver(self, selector: #selector(onRoomRemoved(_:)), name: .init(roomRemovedNotification), object: nil)
    }

    func updateAvailableActions() {
        guard let info else { return }
        let actions = info.roomActions(rootController: self)
        navigationItem.rightBarButtonItem = actions.isEmpty ? nil : UIBarButtonItem(image: UIImage(named: "cloud_file_more"),
                                                                                    style: .plain,
                                                                                    target: nil,
                                                                                    action: nil)
        navigationItem.rightBarButtonItem?.viewContainingControllerProvider = { [unowned self] in
            self
        }
        navigationItem.rightBarButtonItem?.setupCommonCustomAlert(actions, preferContextMenu: !(view.window?.traitCollection.hasCompact ?? true))
    }

    @IBAction func onClickCopy(_: Any) {
        guard let info else { return }
        UIPasteboard.general.string = info.inviteCode.formatterInviteCode
        toast(localizeStrings("Copy Success"))
    }

    func setupViews() {
        view.backgroundColor = .color(type: .background, .weak)
        func loopTextColor(view: UIView) {
            if let stack = view as? UIStackView {
                stack.backgroundColor = self.view.backgroundColor
                stack.arrangedSubviews.forEach { loopTextColor(view: $0) }
            } else if let label = view as? UILabel {
                if label.font.pointSize >= 16 {
                    label.textColor = .color(type: .text, .strong)
                } else {
                    label.textColor = .color(type: .text)
                }
            } else if let imageView = view as? UIImageView {
                imageView.tintColor = .color(type: .text)
            } else if let button = view as? UIButton {
                button.tintColor = .color(type: .text)
            } else {
                view.subviews.forEach { loopTextColor(view: $0) }
            }
        }

        loopTextColor(view: mainStackView)

        let line = UIView()
        line.backgroundColor = .borderColor
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.equalTo(mainStackView)
            make.top.equalTo(mainStackView.snp.bottom).offset(16)
            make.height.equalTo(commonBorderWidth)
        }

        inviteButton.layer.borderWidth = commonBorderWidth
        inviteButton.setTraitRelatedBlock { btn in
            let borderColor = UIColor.color(light: .grey3, dark: .grey6).resolvedColor(with: btn.traitCollection)
            let titleColor = UIColor.color(light: .grey6, dark: .grey3).resolvedColor(with: btn.traitCollection)
            btn.layer.borderColor = borderColor.cgColor
            btn.setTitleColor(titleColor, for: .normal)
        }

        replayButton.layer.borderWidth = commonBorderWidth
        replayButton.setTraitRelatedBlock { btn in
            let borderColor = UIColor.color(light: .grey3, dark: .grey6).resolvedColor(with: btn.traitCollection)
            let titleColor = UIColor.color(light: .grey6, dark: .grey3).resolvedColor(with: btn.traitCollection)
            btn.layer.borderColor = borderColor.cgColor
            btn.setTitleColor(titleColor, for: .normal)
        }
    }

    func updateEnterRoomButtonTitle() {
        guard let info else { return }
        if info.isOwner, info.roomStatus == .Idle {
            enterRoomButton.setTitle(localizeStrings("Start Class"), for: .normal)
        } else {
            enterRoomButton.setTitle(localizeStrings("Enter Room"), for: .normal)
        }
    }

    func updateViewWithCurrentStatus() {
        guard let info else { return }

        title = info.title

        let beginTime: Date
        let endTime: Date
        let status: RoomStartStatus
        let roomType: ClassRoomType
        beginTime = info.beginTime
        endTime = info.endTime
        status = info.roomStatus
        roomType = info.roomType

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeStr = formatter.string(from: beginTime) + "~" + formatter.string(from: endTime)
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        let dateStr = formatter.string(from: beginTime)
        timeLabel.text = dateStr + " " + timeStr
        statusLabel.text = localizeStrings(status.rawValue)
        statusLabel.textColor = status == .Started ? .color(type: .success) : .color(type: .text)

        roomNumberLabel.text = info.inviteCode.formatterInviteCode
        roomTypeLabel.text = localizeStrings(roomType.rawValue)

        if status == .Stopped {
            replayButton.isHidden = !info.hasRecord
            roomOperationStackView.arrangedSubviews.forEach {
                if $0 !== replayButton {
                    $0.isHidden = true
                }
            }
        } else {
            replayButton.isHidden = true
            roomOperationStackView.arrangedSubviews.forEach {
                if $0 !== replayButton {
                    $0.isHidden = false
                }
            }
        }

        roomOperationStackView.isHidden = hideAllActions
    }

    // MARK: - Action

    @IBAction func onClickReplay() {
        guard let info else { return }
        showActivityIndicator()
        ApiProvider.shared.request(fromApi: RecordDetailRequest(uuid: info.roomUUID)) { [weak self] result in
            guard let self else { return }
            self.stopActivityIndicator()
            switch result {
            case let .success(recordInfo):
                let viewModel = MixReplayViewModel(recordDetail: recordInfo)
                let vc = MixReplayViewController(viewModel: viewModel)
                self.mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            case let .failure(error):
                self.toast(error.localizedDescription)
            }
        }
    }

    @IBAction func onClickInvite(_: UIButton) {
        guard let info else { return }
        let vc = InviteViewController(shareInfo: .init(roomDetail: info))
        mainContainer?.concreteViewController.present(vc, animated: true)
    }

    @IBAction func onClickEnterRoom(_ sender: UIButton) {
        guard let info else { return }
        ClassroomCoordinator.shared.enterClassroom(uuid: info.roomUUID,
                                                   periodUUID: info.periodicUUID,
                                                   basicInfo: info,
                                                   sender: sender)
    }

    @IBOutlet var inviteButton: UIButton!
    @IBOutlet var roomNumberTitleLabel: UILabel!
    @IBOutlet var enterRoomButton: UIButton!
    @IBOutlet var mainStackView: UIStackView!
    @IBOutlet var roomTypeLabel: UILabel!
    @IBOutlet var roomNumberLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var roomOperationStackView: UIStackView!
    @IBOutlet var replayButton: UIButton!
}

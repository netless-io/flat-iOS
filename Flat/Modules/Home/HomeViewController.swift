//
//  HomeViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import DZNEmptyDataSet
import Kingfisher
import UIKit

extension RoomStartStatus {
    var textColor: UIColor {
        if self == .Idle {
            return .init(hexString: "#E99434")
        } else if self == .Started {
            return .init(hexString: "#7EC452")
        }
        return .color(type: .text)
    }
}

class HomeViewController: UIViewController {
    let roomTableViewCellIdentifier = "roomTableViewCellIdentifier"

    var showingHistory: Bool = false {
        didSet {
            historyButton.isSelected = showingHistory
        }
    }

    lazy var list: [RoomBasicInfo] = [] {
        didSet {
            guard list != oldValue else { return }
            tableView.reloadData()
        }
    }

    // MARK: - LifeCycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        mainSplitViewController?.detailUpdateDelegate = self
        loadRooms(nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadEmptyDataSet()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        observeNotification()
        observeClassLeavingNotification()
    }

    // MARK: - Action

    @objc func onClickSetting() {
        mainContainer?.push(SettingViewController())
    }

    @objc func onClickProfile() {
        mainContainer?.push(ProfileViewController())
    }

    @objc func onClickCreate() {
        mainContainer?.concreteViewController.present(CreateClassRoomViewController(), animated: true)
    }

    @objc func onClickJoin() {
        mainContainer?.concreteViewController.present(JoinRoomViewController(), animated: true)
    }

    @objc func onClickBook() {
        showAlertWith(message: localizeStrings("Coming soon"))
    }

    @objc func onRefresh(_ sender: UIRefreshControl) {
        // Update for sometimes network doesn't work
        applyAvatar()

        loadRooms(sender) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                sender.endRefreshing()
            }
        }
    }

    @objc func onClickHistory() {
        //  Just push on iPhone device
        if isCompact() {
            mainContainer?.push(historyViewController)
            return
        }
        showingHistory = !showingHistory
        if showingHistory {
            mainContainer?.push(historyViewController)
        } else {
            mainSplitViewController?.cleanSecondary()
        }
    }

    // MARK: - Data

    func loadRooms(_: Any?, completion: @escaping ((Error?) -> Void) = { _ in }) {
        ApiProvider.shared.request(fromApi: RoomListRequest(page: 1)) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(list):
                self.list = list
                self.tableView.showLoadedAll(!list.isEmpty)
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

    @objc func onClassLeavingNotification(_ notification: Notification) {
        guard
            let startStatus = notification.userInfo?["startStatus"] as? RoomStartStatus,
            let roomUUID = notification.userInfo?["roomUUID"] as? String
        else { return }
        guard let vc = mainContainer?.concreteViewController else { return }
        let isStop = startStatus == .Stopped
        if let vc = vc as? MainSplitViewController {
            if isStop {
                vc.show(vc.emptyDetailController)
            } else {
                if !vc.viewControllers
                    .map({ ($0 as? UINavigationController)?.topViewController ?? $0 })
                    .contains(where: { ($0 as? RoomDetailViewController)?.info?.roomUUID == roomUUID })
                {
                    RoomBasicInfo.fetchInfoBy(uuid: roomUUID, periodicUUID: nil) { result in
                        switch result {
                        case let .success(r):
                            let roomDetailController = RoomDetailViewController()
                            roomDetailController.updateInfo(r)
                            vc.push(roomDetailController)
                        case .failure: return
                        }
                    }
                }
            }
        } else if vc is MainTabBarController, let navi = navigationController {
            var vcs = navi.viewControllers
            vcs = vcs.filter {
                if $0 is JoinRoomViewController { return false }
                if $0 is CreateClassRoomViewController { return false }
                if isStop, $0 is RoomDetailViewController { return false }
                return true
            }
            if !isStop {
                if !vcs.contains(where: { ($0 as? RoomDetailViewController)?.info?.roomUUID == roomUUID }) {
                    if let info = list.first(where: { $0.roomUUID == roomUUID }) {
                        let roomDetailController = RoomDetailViewController()
                        roomDetailController.updateInfo(info)
                        vcs.append(roomDetailController)
                    } else {
                        RoomBasicInfo.fetchInfoBy(uuid: roomUUID, periodicUUID: nil) { result in
                            switch result {
                            case let .success(r):
                                let roomDetailController = RoomDetailViewController()
                                roomDetailController.updateInfo(r)
                                vcs.append(roomDetailController)
                                navi.setViewControllers(vcs, animated: false)
                            case .failure: return
                            }
                        }
                    }
                }
            }
            navi.setViewControllers(vcs, animated: false)
        }
    }

    @objc func onRoomRemovedNotification(_ noti: Notification) {
        guard
            let roomUUID = noti.userInfo?["roomUUID"] as? String,
            let index = list.firstIndex(where: { $0.roomUUID == roomUUID })
        else { return }
        tableView.beginUpdates()
        list.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
        tableView.endUpdates()
    }

    // MARK: - Private

    func observeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onRoomRemovedNotification(_:)),
                                               name: .init(rawValue: roomRemovedNotification),
                                               object: nil)
        NotificationCenter.default.rx
            .notification(avatarUpdateNotificationName)
            .subscribe(with: self, onNext: { ws, _ in
                ws.applyAvatar()
            })
            .disposed(by: rx.disposeBag)
    }

    func observeClassLeavingNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onClassLeavingNotification(_:)),
                                               name: classRoomLeavingNotificationName,
                                               object: nil)
    }

    func setupViews() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.refreshControl = .init(frame: .zero)
        tableView.refreshControl?.addTarget(self, action: #selector(onRefresh(_:)), for: .valueChanged)
        fillTopSafeAreaWith(color: .color(type: .background))
    }

    func createHeaderButton(title: String, imageName: String, target: Any?, action: Selector) -> UIButton {
        let button = SpringButton(type: .custom)
        button.setImage(UIImage(named: imageName), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setTitleColor(.color(type: .text), for: .normal)
        button.setTitle(title, for: .normal)
        button.verticalCenterImageAndTitleWith(8)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    func applyAvatar() {
        guard avatarButton.superview != nil else { return }
        let scale = UIScreen.main.scale
        let size = CGSize(width: avatarWidth, height: avatarWidth).applying(.init(scaleX: scale, y: scale))
        let processor = ResizingImageProcessor(referenceSize: size)
        avatarButton.imageEdgeInsets = .init(inset: (tableHeaderItemWidth - avatarWidth) / 2)
        avatarButton.kf.setImage(with: AuthStore.shared.user?.avatar,
                                 for: .normal,
                                 options: [.processor(processor)])
    }

    // MARK: - Lazy

    lazy var avatarButton: UIButton = {
        let avatarButton = SpringButton(type: .custom)
        avatarButton.clipsToBounds = true
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.contentMode = .scaleAspectFill
        avatarButton.isUserInteractionEnabled = true
        avatarButton.setupCommonCustomAlert([
            .init(title: localizeStrings("Profile"), image: UIImage(named: "profile"), style: .default, handler: { _ in
                self.onClickProfile()
            }),
            .init(title: localizeStrings("Setting"), image: UIImage(named: "setting"), style: .default, handler: { _ in
                self.onClickSetting()
            }),
            .cancel,
        ])
        return avatarButton
    }()

    let tableHeaderItemWidth: CGFloat = 44
    let avatarWidth: CGFloat = 24

    lazy var tableHeader: UIView = {
        let header = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 166)))
        header.backgroundColor = .color(type: .background)
        let stack = UIStackView(arrangedSubviews: [
            createHeaderButton(title: localizeStrings("Join Room"), imageName: "room_join", target: self, action: #selector(onClickJoin)),
            createHeaderButton(title: localizeStrings("Start Now"), imageName: "room_create", target: self, action: #selector(onClickCreate)),
            createHeaderButton(title: localizeStrings("Book Room"), imageName: "room_book", target: self, action: #selector(onClickBook)),
        ])
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        header.addSubview(stack)
        stack.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(82)
        }

        let titleLabel = UILabel()
        titleLabel.text = localizeStrings("Home")
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .color(type: .text, .strong)
        header.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(header.safeAreaLayoutGuide).offset(16)
        }

        let operationStack = UIStackView(arrangedSubviews: [historyButton])
        if let hasSideBar = mainContainer?.hasSideBar, !hasSideBar {
            operationStack.addArrangedSubview(avatarButton)
            let avatarMask = CAShapeLayer()
            avatarMask.path = UIBezierPath(arcCenter: .init(x: tableHeaderItemWidth / 2, y: tableHeaderItemWidth / 2), radius: avatarWidth / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
            avatarButton.layer.mask = avatarMask
            applyAvatar()
        }
        operationStack.axis = .horizontal
        operationStack.distribution = .fillEqually
        header.addSubview(operationStack)
        operationStack.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview()
            make.height.equalTo(tableHeaderItemWidth)
            make.width.equalTo(CGFloat(operationStack.arrangedSubviews.count) * tableHeaderItemWidth)
        }
        return header
    }()

    lazy var historyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(onClickHistory), for: .touchUpInside)
        button.setTraitRelatedBlock { v in
            let normalImage = UIImage(named: "history")?.tintColor(.color(type: .text).resolvedColor(with: v.traitCollection))
            let selectedImage = UIImage(named: "history")?.tintColor(.color(type: .primary).resolvedColor(with: v.traitCollection))
            v.setImage(normalImage, for: .normal)
            v.setImage(selectedImage, for: .selected)
        }
        return button
    }()

    lazy var historyViewController = HistoryViewController()

    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.contentInsetAdjustmentBehavior = .always
        table.backgroundColor = .color(type: .background)
        table.showsVerticalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 76
        table.emptyDataSetDelegate = self
        table.emptyDataSetSource = self
        table.register(.init(nibName: String(describing: RoomTableViewCell.self), bundle: nil), forCellReuseIdentifier: roomTableViewCellIdentifier)
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }
        return table
    }()

    lazy var detailViewController = RoomDetailViewController()
}

// MARK: - Tableview

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: roomTableViewCellIdentifier, for: indexPath) as! RoomTableViewCell
        cell.render(info: list[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isCompact() {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let item = list[indexPath.row]
        detailViewController.updateInfo(item)
        mainContainer?.push(detailViewController)
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        tableHeader.bounds.height
    }

    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let identifier = (configuration.identifier as? NSString) else { return }
        let index = Int(identifier.intValue)

        if !isCompact() {
            if let selected = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selected, animated: true)
            }
            tableView.selectRow(at: .init(row: index, section: 0), animated: true, scrollPosition: .none)
        }

        if let controller = animator.previewViewController as? RoomDetailViewController,
           let item = controller.info
        {
            detailViewController.updateInfo(item)
            mainContainer?.push(detailViewController)
        }
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        let item = list[indexPath.row]
        let actions = item.roomActions(rootController: self)
        let previewProvider: UIContextMenuContentPreviewProvider = { [unowned self] in
            let vc = RoomDetailViewController()
            vc.hideAllActions = true
            vc.updateInfo(item)
            let width = self.view.bounds.width - 88
            vc.preferredContentSize = .init(width: width, height: 280)
            return vc
        }
        let identifier = indexPath.row.description as NSString
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: previewProvider) { _ in
            let uiActions = actions.compactMap { action -> UIAction? in
                if action.isCancelAction() {
                    return nil
                }
                return UIAction(title: action.title,
                                attributes: action.style == .destructive ? .destructive : []) { _ in
                    action.handler?(action)
                }
            }
            return UIMenu(title: "", children: uiActions)
        }
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        0
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        tableHeader
    }
}

// MARK: - EmptyData

extension HomeViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet _: UIScrollView) -> NSAttributedString? {
        .init(string: localizeStrings("No room at the moment"),
              attributes: [
                  .foregroundColor: UIColor.color(type: .text),
                  .font: UIFont.systemFont(ofSize: 14),
              ])
    }

    func image(forEmptyDataSet _: UIScrollView) -> UIImage? {
        UIImage(named: "room_empty", in: nil, compatibleWith: traitCollection)
    }

    func emptyDataSetShouldAllowScroll(_: UIScrollView) -> Bool {
        true
    }

    func verticalOffset(forEmptyDataSet _: UIScrollView) -> CGFloat {
        tableHeader.bounds.height / 2
    }
}

extension HomeViewController: MainSplitViewControllerDetailUpdateDelegate {
    /// If it was in splitVC, take top
    var currentDetailVC: RoomDetailViewController? {
        guard let split = mainSplitViewController else { return nil }
        if #available(iOS 14.0, *) {
            return (split.viewController(for: .secondary) as? UINavigationController)?.topViewController as? RoomDetailViewController
        } else {
            return (split.viewControllers.last as? UINavigationController)?.topViewController as? RoomDetailViewController
        }
    }

    func mainSplitViewControllerDidUpdateDetail(_ vc: UIViewController, sender _: Any?) {
        let isHistory = (vc as? HistoryViewController) != nil
        showingHistory = isHistory

        // If select a vc is not the room detail, deselect the tableview
        if let selectedItem = tableView.indexPathForSelectedRow {
            let item = list[selectedItem.row]
            if let vc = ((vc as? UINavigationController)?.topViewController as? RoomDetailViewController),
               vc.info?.roomUUID == item.roomUUID
            {
                return
            }
            if let vc = vc as? RoomDetailViewController,
               vc.info?.roomUUID == item.roomUUID
            {
                return
            }
            tableView.deselectRow(at: selectedItem, animated: true)
        }
    }
}

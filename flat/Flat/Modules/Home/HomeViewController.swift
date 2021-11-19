//
//  HomeViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import SnapKit
import Kingfisher
import EmptyDataSet_Swift

let homeShouldUpdateListNotification = "homeShouldUpdateListNotification"

extension RoomStartStatus {
    var textColor: UIColor {
        if self == .Idle {
            return .init(hexString: "#E99434")
        } else if self == .Started {
            return .init(hexString: "#7EC452")
        }
        return .subText
    }
}

/// WARNING: Change these constants according to your project's design
private struct Const {
    /// Image height/width for Large NavBar state
    static let ImageSizeForLargeState: CGFloat = 40
    /// Margin from right anchor of safe area to right anchor of Image
    static let ImageRightMargin: CGFloat = 16
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Large NavBar state
    static let ImageBottomMarginForLargeState: CGFloat = 12
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Small NavBar state
    static let ImageBottomMarginForSmallState: CGFloat = 6
    /// Image height/width for Small NavBar state
    static let ImageSizeForSmallState: CGFloat = 32
    /// Height of NavBar for Small state. Usually it's just 44
    static let NavBarHeightSmallState: CGFloat = 44
    /// Height of NavBar for Large state. Usually it's just 96.5 but if you have a custom font for the title, please make sure to edit this value since it changes the height for Large state of NavBar
    static let NavBarHeightLargeState: CGFloat = 96.5
}

class HomeViewController: UIViewController {
    enum ListStyle: Hashable {
        case exist
        case history
    }
    
    let roomTableViewCellIdentifier = "roomTableViewCellIdentifier"
    
    var cachedList: [ListStyle: [RoomListInfo]] = [:]
    
    var style: ListStyle = .exist {
        didSet {
            guard style != oldValue else { return }
            if let cache = cachedList[style] {
                list = cache
            } else {
                list = []
                loadRooms(nil)
            }
            tableView.reloadData()
        }
    }
    
    lazy var list: [RoomListInfo] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        splitViewController?.delegate = self
        avatarButton.isHidden = false
        loadRooms(nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        avatarButton.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        observeNotification()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let headerRatio: CGFloat = 125.0 / 110.0
        let width = view.bounds.width
        let itemWidth = width / 3
        let itemHeight = itemWidth / headerRatio
        tableHeader.frame = .init(origin: .zero, size: .init(width: itemWidth, height: itemHeight))
        tableView.tableHeaderView = tableHeader
        tableView.reloadData()
        tableView.reloadEmptyDataSet()
    }
    
    // MARK: - Action
    @objc func onClickSetting() {
        if let split = splitViewController {
            let vc = BaseNavigationViewController(rootViewController: SettingViewController())
            split.showDetailViewController(vc, sender: nil)
        } else {
            navigationController?.pushViewController(SettingViewController(), animated: true)
        }
    }
    
    @objc func onClickProfile() {
        
    }
    
    @objc func onClickCreate() {
        let vc = CreateClassRoomViewController()
        if let split = splitViewController {
            split.showDetailViewController(BaseNavigationViewController(rootViewController: vc), sender: nil)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func onClickJoin() {
        let vc = JoinRoomViewController()
        if let split = splitViewController {
            split.showDetailViewController(BaseNavigationViewController(rootViewController: vc), sender: nil)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func onClickBook() {
        showAlertWith(message: "Coming soon")
    }
    
    @objc func onClickAvatarBeforeiOS14(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(.init(title: NSLocalizedString("Profile", comment: ""), style: .default, handler: {  _ in
            self.onClickProfile()
        }))
        alertController.addAction(.init(title: NSLocalizedString("Setting", comment: ""), style: .default, handler: { _ in
            self.onClickSetting()
        }))
        alertController.modalPresentationStyle = .popover
        let popPresent = alertController.popoverPresentationController
        popPresent?.sourceView = sender
        popPresent?.sourceRect = sender.bounds
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func onRefresh(_ sender: UIRefreshControl) {
        loadRooms(sender) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                sender.endRefreshing()
            }
        }
    }
    
    // MARK: - Date
    func loadRooms(_ sender: Any?, completion: @escaping ((Error?)->Void) = { _ in }) {
        func handleResult(_ result: Result<[RoomListInfo], ApiError>) {
            switch result {
            case .success(let list):
                self.list = list
                self.cachedList[style] = list
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
        
        switch style {
        case .exist:
            ApiProvider.shared.request(fromApi: RoomListRequest(page: 1)) { result in
                handleResult(result)
            }
        case .history:
            ApiProvider.shared.request(fromApi: RoomHistoryRequest(page: 1)) { result in
                handleResult(result)
            }
        }
    }
    
    @objc func onUpdateNotificaton(_ noti: Notification) {
        loadRooms(nil)
    }
    
    // MARK: - Private
    func observeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onUpdateNotificaton(_:)), name: .init(rawValue: "homeShouldUpdateListNotification"), object: nil)
    }
    
    func setupViews() {
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .white
        navigationItem.title = NSLocalizedString("Home", comment: "")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // https://www.uptech.team/blog/build-resizing-image-in-navigation-bar-with-large-title
        // Initial setup for image for Large NavBar state since the the screen always has Large NavBar once it gets opened
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -Const.ImageRightMargin),
            avatarButton.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -Const.ImageBottomMarginForLargeState),
            avatarButton.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState),
            avatarButton.widthAnchor.constraint(equalTo: avatarButton.heightAnchor)
            ])
        
        tableView.refreshControl = .init(frame: .zero)
        tableView.refreshControl?.addTarget(self, action: #selector(onRefresh(_:)), for: .valueChanged)
    }
    
    func shouldShowCalendarAt(indexPath: IndexPath) -> Bool {
        let lastIndex = indexPath.row - 1
        guard lastIndex >= 0 else { return true }
        return !list[indexPath.row].beginTime.isSameDayTo(list[lastIndex].beginTime)
    }
    
    func config(cell: RoomTableViewCell, with room: RoomListInfo, indexPath: IndexPath) {
        cell.selectionStyle = .none
        cell.calendarView.isHidden = !shouldShowCalendarAt(indexPath: indexPath)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let dateStr = formatter.string(from: room.beginTime)
        
        if Calendar.current.isDateInToday(room.beginTime) {
            cell.calendarLabel.text = dateStr + " · " + NSLocalizedString("Today", comment: "")
        } else {
            let weekStr = formatter.shortWeekdaySymbols[Calendar.current.component(.weekday, from: room.beginTime) - 1]
            cell.calendarLabel.text = dateStr + " · " + weekStr
        }
        
        let timeFormmater = DateFormatter()
        timeFormmater.timeStyle = .short
        timeFormmater.dateFormat = "HH:mm"
        cell.roomTimeLabel.text = timeFormmater.string(from: room.beginTime) + " ~ " + timeFormmater.string(from: room.endTime)
        cell.roomTitleLabel.text = room.title
        
        let displayStatus = room.roomStatus.getDisplayStatus()
        cell.statusLabel.text = NSLocalizedString(displayStatus.rawValue, comment: "")
        cell.statusLabel.textColor = displayStatus.textColor
    }
    
    private func moveAndResizeImage(for height: CGFloat) {
        let coeff: CGFloat = {
            let delta = height - Const.NavBarHeightSmallState
            let heightDifferenceBetweenStates = (Const.NavBarHeightLargeState - Const.NavBarHeightSmallState)
            return delta / heightDifferenceBetweenStates
        }()

        let factor = Const.ImageSizeForSmallState / Const.ImageSizeForLargeState

        let scale: CGFloat = {
            let sizeAddendumFactor = coeff * (1.0 - factor)
            return min(1.0, sizeAddendumFactor + factor)
        }()

        // Value of difference between icons for large and small states
        let sizeDiff = Const.ImageSizeForLargeState * (1.0 - factor) // 8.0
        let yTranslation: CGFloat = {
            /// This value = 14. It equals to difference of 12 and 6 (bottom margin for large and small states). Also it adds 8.0 (size difference when the image gets smaller size)
            let maxYTranslation = Const.ImageBottomMarginForLargeState - Const.ImageBottomMarginForSmallState + sizeDiff
            return max(0, min(maxYTranslation, (maxYTranslation - coeff * (Const.ImageBottomMarginForSmallState + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)

        avatarButton.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation, y: yTranslation)
    }
    
    func createHeaderButton(title: String, imageName: String, target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setImage(UIImage(named: imageName), for: .normal)
        button.setTitle(title, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.verticalCenterImageAndTitleWith(8)
        return button
    }
    
    // MARK: - Lazy
    lazy var avatarButton: UIButton = {
        let avatarButton = UIButton(type: .custom)
        avatarButton.backgroundColor = .lightGray
        avatarButton.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        avatarButton.clipsToBounds = true
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.contentMode = .scaleAspectFill
        avatarButton.kf.setBackgroundImage(with: AuthStore.shared.user?.avatar, for: .normal)
        avatarButton.isUserInteractionEnabled = true
        if #available(iOS 14.0, *) {
            avatarButton.menu = UIMenu.init(title: "",
                                            image: UIImage(named: "login_logo"),
                                            identifier: nil,
                                            children: [
                                                UIAction(title: NSLocalizedString("Profile", comment: ""),
                                                         image: UIImage(named: "profile")
                                                        ) { _ in
                                                            self.onClickProfile()
                                                        },
                                                UIAction(title: NSLocalizedString("Setting", comment: ""),
                                                         image: UIImage(named: "setting")
                                                        ) { _ in
                                                            self.onClickSetting()
                                                        }])
            avatarButton.showsMenuAsPrimaryAction = true
        } else {
            avatarButton.addTarget(self, action: #selector(onClickAvatarBeforeiOS14(_:)), for: .touchUpInside)
        }
        return avatarButton
    }()
    
    lazy var tableHeader: UIView = {
        let header = UIView()
        let stack = UIStackView(arrangedSubviews: [
            createHeaderButton(title: NSLocalizedString("Join Room", comment: ""), imageName: "room_join", target: self, action: #selector(onClickJoin)),
            createHeaderButton(title: NSLocalizedString("Create Room", comment: ""), imageName: "room_create", target: self, action: #selector(onClickCreate)),
            createHeaderButton(title: NSLocalizedString("Book Room", comment: ""), imageName: "room_book", target: self, action: #selector(onClickBook))
        ])
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        header.addSubview(stack)
        stack.snp.makeConstraints({ $0.edges.equalToSuperview() })
        return header
    }()
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.tableHeaderView = tableHeader
        table.delegate = self
        table.dataSource = self
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
    
    lazy var tabbar: HomeTabbar = {
        let tabbar = HomeTabbar(frame: .zero)
        tabbar.items = [tabbar.addItem(title: NSLocalizedString("Room List", comment: ""), tag: 0),
                        tabbar.addItem(title: NSLocalizedString("History", comment: ""), tag: 1)]
        tabbar.selectedItem = tabbar.items?.first
        tabbar.delegate = self
        return tabbar
    }()
}

// MARK: - Tableview
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        moveAndResizeImage(for: height)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        list.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        shouldShowCalendarAt(indexPath: indexPath) ? 105 : 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: roomTableViewCellIdentifier, for: indexPath) as! RoomTableViewCell
        let item = list[indexPath.row]
        config(cell: cell, with: item, indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = list[indexPath.row]
        let vc = RoomDetailViewController(info: item)
        if let split = splitViewController {
            let navi = BaseNavigationViewController(rootViewController: vc)
            split.showDetailViewController(navi, sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        48
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tabbar
    }
}

extension HomeViewController: EmptyDataSetDelegate, EmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        .init(string: NSLocalizedString("No room at the moment", comment: ""), attributes: [
            .foregroundColor: UIColor.subText,
            .font: UIFont.systemFont(ofSize: 14)
        ])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        UIImage(named: "room_empty")
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        true
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        66
    }
}

extension HomeViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.firstIndex(of: item) else { return }
        if index == 0 {
            style = .exist
        } else {
            style = .history
        }
    }
}

extension HomeViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        if let selectedItem = tableView.indexPathForSelectedRow {
            let item = list[selectedItem.row]
            if let vc = (vc as? UINavigationController)?.topViewController as? RoomDetailViewController {
                if vc.info.roomUUID == item.roomUUID {
                    return false
                }
            }
            tableView.deselectRow(at: selectedItem, animated: true)
        }
        return false
    }
}

//
//  SecurityViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/16.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

extension LoginType {
    var accountBindIconImage: UIImage? {
        UIImage(named: "account_\(rawValue)")
    }

    var accountTitle: String { localizeStrings("Account_\(rawValue)") }
}

class SecurityViewController: UIViewController {
    struct BindingItem {
        let type: LoginType
        let isBind: Bool
        let detail: String
    }

    enum DisplayItem {
        case binding(BindingItem)
        case updatePassword
        case accountCancel
    }
    
    struct Section {
        let title: String
        let items: [DisplayItem]
    }

    var appleBinding: AppleBinding?
    
    var sections: [Section] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBindingInfo(showLoading: sections.isEmpty)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        title = localizeStrings("AccountSecurity")
        view.backgroundColor = .color(type: .background)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func loadBindingInfo(showLoading: Bool) {
        if showLoading {
            showActivityIndicator()
        }
        ApiProvider.shared.request(fromApi: BindListRequest()) { [weak self] result in
            guard let self else { return }
            if showLoading {
                self.stopActivityIndicator()
            }
            switch result {
            case let .success(info):
                let env = Env()
                let items = LoginType.allCases
                    .filter { !env.disabledLoginTypes.contains($0) }
                    .map { type in
                        let isBind: Bool
                        let detail: String
                        switch type {
                        case .apple:
                            isBind = info.apple
                            detail = info.meta.apple
                        case .email:
                            isBind = info.email
                            detail = info.meta.email
                        case .phone:
                            isBind = info.phone
                            detail = info.meta.phone
                        case .github:
                            isBind = info.github
                            detail = info.meta.github
                        case .wechat:
                            isBind = info.wechat
                            detail = info.meta.wechat
                        case .google:
                            isBind = info.google
                            detail = info.meta.google
                        }
                        let item = BindingItem(type: type, isBind: isBind, detail: detail)
                        return item
                    }
                self.sections = [
                    .init(title: localizeStrings("Account binding information"), items: items.map { DisplayItem.binding($0) }),
                    .init(title: localizeStrings("Password"), items: [.updatePassword]),
                    .init(title: localizeStrings("Cancellation"), items: [.accountCancel]),
                ]
            case let .failure(failure):
                self.toast(failure.localizedDescription)
            }
        }
    }

    // MARK: - Lazy  -

    let cellIdentifier = "cellIdentifier"
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .color(type: .background)
        view.register(UINib(nibName: String(describing: SettingTableViewCell.self), bundle: nil), forCellReuseIdentifier: cellIdentifier)
        view.separatorStyle = .none
        view.delegate = self
        view.dataSource = self
        view.tableHeaderView = .init(frame: .init(origin: .zero, size: .init(width: 0, height: 12)))
        return view
    }()
}

extension SecurityViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        48
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        24
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        12
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        UIView()
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView(frame: .zero)
        view.backgroundColor = .red
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.text = sections[section].title
        label.textColor = .color(type: .text, .weak)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        return view
    }

    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func bind(type: LoginType) {
        switch type {
        case .email:
            navigationController?.pushViewController(BindEmailViewController(), animated: true)
        case .phone:
            navigationController?.pushViewController(BindPhoneViewController(), animated: true)
        case .apple:
            showActivityIndicator()
            appleBinding = AppleBinding { [weak self] error in
                guard let self else { return }
                self.appleBinding = nil
                stopActivityIndicator()
                if let error, !error.localizedDescription.isEmpty {
                    toast(error.localizedDescription)
                } else {
                    loadBindingInfo(showLoading: false)
                }
            }
            appleBinding?.startBinding(sender: view)
        case .wechat:
            showActivityIndicator()
            let binding = WechatBinding { [weak self] error in
                guard let self else { return }
                stopActivityIndicator()
                if let error {
                    toast(error.localizedDescription)
                } else {
                    loadBindingInfo(showLoading: false)
                }
            }
            binding.startBinding(onCoordinator: globalLaunchCoordinator!)
        case .google, .github:
            guard let bindingLink = type.uuidBindingLink() else { return }
            showActivityIndicator()
            let binding = WebLinkBindingItem { [weak self] error in
                guard let self else { return }
                stopActivityIndicator()
                if let error {
                    toast(error.localizedDescription)
                } else {
                    loadBindingInfo(showLoading: false)
                }
            }
            binding.startBinding(urlMaker: bindingLink, sender: view, onCoordinator: globalLaunchCoordinator!)
        }
    }

    func unbind(type: LoginType) {
        let hasPhone = sections
            .flatMap { $0.items }
            .contains(where: {
                if case .binding(let item) = $0,
                   item.type == .phone && item.isBind {
                    return true
                }
                return false
            })
        let hasEmail = sections
            .flatMap { $0.items }
            .contains(where: {
                if case .binding(let item) = $0,
                   item.type == .email && item.isBind {
                    return true
                }
                return false
            })
        let importantBindTypeDiabled: Bool
            
        switch (type, hasPhone, hasEmail) {
        case (.email, false, true):
            importantBindTypeDiabled = true
        case (.phone, true, false):
            importantBindTypeDiabled = true
        default:
            importantBindTypeDiabled = false
        }
        showCheckAlert(message: localizeStrings("Unbound Tips")) {
            if importantBindTypeDiabled {
                self.toast(localizeStrings("AtLeastBindPhoneOrEmailTips"), timeInterval: 5)
                return
            }
            self.showActivityIndicator()
            ApiProvider.shared.request(fromApi: RemoveBindingRequest(type: type)) { result in
                self.stopActivityIndicator()
                switch result {
                case .success:
                    self.loadBindingInfo(showLoading: false)
                case let .failure(error):
                    self.toast(error.localizedDescription)
                }
            }
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case let .binding(bindingItem):
            let type = bindingItem.type
            if bindingItem.isBind {
                unbind(type: type)
            } else {
                bind(type: type)
            }
        case .updatePassword:
            if AuthStore.shared.user?.hasPassword == true {
                navigationController?.pushViewController(UpdatePasswordViewController(), animated: true)
            } else {
                navigationController?.pushViewController(SetNewPasswordViewController(), animated: true)
            }
        case .accountCancel:
            onClickCancellation()
        }
    }
    
    @objc func onClickCancellation() {
        showActivityIndicator()
        ApiProvider.shared.request(fromApi: AccountCancelationValidateRequest()) { [weak self] result in
            guard let self else { return }
            self.stopActivityIndicator()
            switch result {
            case let .failure(error):
                self.toast(error.localizedDescription)
            case let .success(r):
                if r.alreadyJoinedRoomCount > 0 {
                    self.showAlertWith(title: localizeStrings("ClassesStillLeftTips") + r.alreadyJoinedRoomCount.description, message: "", completionHandler: nil)
                } else {
                    let vc = CancellationViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! SettingTableViewCell
        switch item {
        case let .binding(bindingItem):
            cell.iconImageView.image = bindingItem.type.accountBindIconImage
            cell.settingTitleLabel.text = bindingItem.type.accountTitle
            cell.settingDetailLabel.isHidden = false
            cell.rightArrowView.isHidden = false
            cell.switch.isHidden = true
            cell.settingDetailLabel.text = bindingItem.isBind ? bindingItem.detail.replacingEmpty(with: localizeStrings("Binded")) : localizeStrings("Unbound")
        case .updatePassword:
            cell.iconImageView.image = UIImage(named: "update_password")
            cell.settingTitleLabel.text = localizeStrings("UpdatePassword")
            cell.rightArrowView.isHidden = false
            cell.switch.isHidden = true
            cell.settingDetailLabel.isHidden = true
        case .accountCancel:
            cell.iconImageView.image = UIImage(named: "cancellation")
            cell.settingTitleLabel.text = localizeStrings("AccountCancellation")
            cell.rightArrowView.isHidden = false
            cell.switch.isHidden = true
            cell.settingDetailLabel.isHidden = true
        }
        return cell
    }
}

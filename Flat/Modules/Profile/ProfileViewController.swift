//
//  ProfileUIViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/6.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let cellIdentifier = "profileCellIdentifier"

    let profileUpdate = ProfileUpdate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupObserver()
    }

    func setupObserver() {
        NotificationCenter.default.rx
            .notification(avatarUpdateNotificationName)
            .subscribe(with: self, onNext: { ws, _ in
                ws.tableView.reloadData()
            })
            .disposed(by: rx.disposeBag)
    }

    func setupViews() {
        title = localizeStrings("Profile")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        tableView.reloadData()
    }

    // MARK: - Actions

    func onClickNickName() {
        let alert = UIAlertController(title: localizeStrings("Update nickname"), message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = AuthStore.shared.user?.name
        }
        alert.addAction(.init(title: localizeStrings("Cancel"), style: .cancel))
        alert.addAction(.init(title: localizeStrings("Confirm"), style: .default, handler: { _ in
            guard let text = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty
            else {
                self.toast(localizeStrings("Please enter your nickname"))
                return
            }
            self.showActivityIndicator()
            ApiProvider.shared.request(fromApi: UserRenameRequest(name: text)) { result in
                self.stopActivityIndicator()
                switch result {
                case .success:
                    AuthStore.shared.updateName(text)
                    self.toast(localizeStrings("Update nickname success"))
                    self.tableView.reloadData()
                case let .failure(error):
                    self.toast(error.localizedDescription)
                }
            }
        }))
        present(alert, animated: true)
    }

    // MARK: - Lazy

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .color(type: .background)
        view.separatorStyle = .none
        view.register(ProfileTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.tableHeaderView = .minHeaderView()
        return view
    }()

    // MARK: - Table view data source

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        2
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.row == 0 ? 68 : 48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ProfileTableViewCell
        switch indexPath.row {
        case 0:
            cell.avatarImageView.isHidden = false
            cell.profileDetailTextLabel.isHidden = true
            cell.profileTitleLabel.text = localizeStrings("Avatar")
            cell.avatarImageView.kf.setImage(with: AuthStore.shared.user?.avatarUrl)
        case 1:
            cell.avatarImageView.isHidden = true
            cell.profileDetailTextLabel.isHidden = false
            cell.profileTitleLabel.text = localizeStrings("Nickname")
            cell.profileDetailTextLabel.text = AuthStore.shared.user?.name
        default:
            return cell
        }
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            guard let root = mainContainer?.concreteViewController else { return }
            profileUpdate.startUpdateAvatar(from: root)
        case 1:
            onClickNickName()
        default:
            return
        }
    }
}

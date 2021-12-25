//
//  ProfileUIViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/6.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class ProfileViewController: UITableViewController {
    let cellIdentifier = "profileCellIdentifier"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Profile", comment: "")
        tableView.separatorStyle = .none
        tableView.rowHeight = 47
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        cell.textLabel?.text = NSLocalizedString("Nickname", comment: "")
        cell.detailTextLabel?.text = AuthStore.shared.user?.name ?? ""
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

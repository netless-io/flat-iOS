//
//  SettingViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class SettingViewController: UITableViewController {
    let cellIdentifier = "cellIdentifier"
    var items: [(UIImage, String, String, (NSObject, Selector)?)] = []
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateItems()
    }
    
    func updateItems() {
        items = [
            (UIImage(named: "language")!,
             NSLocalizedString("Language Setting", comment: ""),
             LocaleManager.language?.name ?? "跟随系统",
             (self, #selector(self.onClickLanguage))),
            
            (UIImage(named: "update_version")!,
             NSLocalizedString("Version", comment: ""),
             "v\(Env().version)",
             nil),
            
            (UIImage(named: "message")!,
             NSLocalizedString("Contact Us", comment: ""),
             "",
             (self, #selector(self.onClickContactUs))),
            
            (UIImage(named: "info")!,
             NSLocalizedString("About", comment: ""),
             "",
             (self, #selector(self.onClickAbout)))
        ]
        tableView.reloadData()
    }
    
    func setupViews() {
        title = NSLocalizedString("Setting", comment: "")
        tableView.backgroundColor = .white
        tableView.separatorInset = .init(top: 0, left: 20, bottom: 0, right: 0)
        tableView.separatorStyle = .singleLine
        tableView.register(UINib(nibName: String(describing: SettingTableViewCell.self), bundle: nil), forCellReuseIdentifier: cellIdentifier)
        
        let container = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 40)))
        container.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        tableView.tableFooterView = container
    }
 
    // MARK: - Action
    @objc func onClickLogout() {
        AuthStore.shared.logout()
    }
    
    @objc func onClickAbout() {
        navigationController?.pushViewController(AboutUsViewController(), animated: true)
    }
    
    @objc func onClickLanguage() {
        let alertController = UIAlertController(title: NSLocalizedString("Select Language", comment: ""), message: nil, preferredStyle: .actionSheet)
        let currentLanguage = LocaleManager.language
        for l in Language.allCases {
            alertController.addAction(.init(title: l == currentLanguage ? "\(l.name)\(NSLocalizedString("selected", comment: ""))" : l.name, style: .default, handler: { _ in
                Bundle.set(language: l)
                if #available(iOS 13.0, *) {
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.launch?.reboot()
                } else {
                    (UIApplication.shared.delegate as? AppDelegate)?.launch?.reboot()
                }
                if let split = UIApplication.shared.topViewController?.splitViewController {
                    let vc = BaseNavigationViewController(rootViewController: SettingViewController())
                    split.showDetailViewController(vc, sender: nil)
                } else if let navi = UIApplication.shared.topViewController?.navigationController {
                    navi.pushViewController(SettingViewController(), animated: false)
                }
                print(LocaleManager.languageCode)
            }))
        }
        alertController.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .destructive, handler: nil))
        let popPresent = alertController.popoverPresentationController
        if let cell = tableView.visibleCells.first {
            popPresent?.sourceView = cell
            popPresent?.sourceRect = cell.bounds
        }
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func onClickContactUs() {
        navigationController?.pushViewController(ContactUsViewController(), animated: true)
    }
    
    // MARK: - Lazy
    lazy var logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(hexString: "#F45454").cgColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 4
        button.setTitleColor(.init(hexString: "#F45454"), for: .normal)
        button.setTitle(NSLocalizedString("Logout", comment: ""), for: .normal)
        button.setImage(UIImage(named: "logout")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(onClickLogout), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 0, left: 44, bottom: 0, right: 44)
        return button
    }()
    
    // MARK: - Tableview
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let pairs = items[indexPath.row].3 {
            pairs.0.perform(pairs.1)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! SettingTableViewCell
        cell.iconImageView.image = item.0
        cell.iconImageView.tintColor = .text
        cell.settingTitleLabel.text = item.1
        cell.settingDetailLabel.text = item.2
        return cell
    }
}

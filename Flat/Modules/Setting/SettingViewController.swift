//
//  SettingViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Siren
import UIKit
import Whiteboard
import Zip

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    struct ItemSection {
        let title: String
        let items: [Item]
    }

    struct Item {
        let image: UIImage
        let title: String
        let detail: Any
        let targetAction: (NSObject, Selector)?
    }

    let cellIdentifier = "cellIdentifier"
    var items: [ItemSection] = []

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
            ItemSection(title: localizeStrings("Security"), items:
                [.init(image: UIImage(named: "security")!,
                       title: localizeStrings("AccountSecurity"),
                       detail: "",
                       targetAction: (self, #selector(onClickSecurity(sender:))))]),

            ItemSection(title: localizeStrings("Preferences"), items:
                [.init(image: UIImage(named: "language")!,
                       title: localizeStrings("Language Setting"),
                       detail: LocaleManager.language?.name ?? "跟随系统",
                       targetAction: (self, #selector(onClickLanguage(sender:)))),
                 .init(image: UIImage(named: "command")!,
                       title: localizeStrings("PreferencesSetting"),
                       detail: "",
                       targetAction: (self, #selector(onClickShortcuts(sender:)))),
                 .init(image: UIImage(named: "theme")!,
                       title: localizeStrings("Theme"),
                       detail: Theme.shared.style.description,
                       targetAction: (self, #selector(onClickTheme(sender:))))]),

            ItemSection(title: localizeStrings("Privacy"), items:
                [.init(image: UIImage(named: "personal_collect")!,
                       title: localizeStrings("PersonalInfoCollect"),
                       detail: "",
                       targetAction: (self, #selector(onClickInfoCollect))),
                 .init(image: UIImage(named: "third_share")!,
                       title: localizeStrings("ThirdPartyShare"),
                       detail: "",
                       targetAction: (self, #selector(onClickThirdPartCollect)))]),

            ItemSection(title: localizeStrings("More"), items:
                [.init(image: UIImage(named: "export")!,
                       title: localizeStrings("Export log"),
                       detail: "",
                       targetAction: (self, #selector(onClickExportLog(sender:)))),
                 .init(image: UIImage(named: "about_us")!,
                       title: localizeStrings("About"),
                       detail: "",
                       targetAction: (self, #selector(onClickAbout(sender:)))),
                 .init(image: UIImage(named: "update_version")!,
                       title: localizeStrings("Version"),
                       detail: "Flat v\(Env().version) (\(Env().build))",
                       targetAction: (self, #selector(onVersion(sender:))))]),
        ]
        tableView.reloadData()
    }

    func setupViews() {
        title = localizeStrings("Setting")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Action

    @objc func onClickLogout() {
        AuthStore.shared.logout()
    }

    @objc func onClickInfoCollect() {
        let url = URL(string: Env().webBaseURL.appending("/sensitive?token=\(AuthStore.shared.user!.token)&?theme=\(Theme.shared.style.schemeStringForWeb)"))!
        let vc = WKWebViewController(url: url, isScrollEnabled: true)
        vc.usingClose = false
        vc.navigationItem.title = localizeStrings("PersonalInfoCollect")
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func onClickThirdPartCollect() {
        let url = URL(string: "https://flat.whiteboard.agora.io/privacy-extra/libraries.html")!
        let vc = WKWebViewController(url: url, isScrollEnabled: true)
        vc.usingClose = false
        vc.navigationItem.title = localizeStrings("ThirdPartyShare")
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func onVersion(sender _: Any?) {
        let url = URL(string: "https://itunes.apple.com/app/id1598891661")!
        UIApplication.shared.open(url)
    }

    @objc func onClickExportLog(sender: Any?) {
        let files = sbLogURLs()
        if files.isEmpty {
            toast("log not exist")
            return
        }
        showActivityIndicator()
        let id = AuthStore.shared.user?.userUUID ?? "unknown"
        let zipUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(id)-flat.zip")
        if FileManager.default.fileExists(atPath: zipUrl.path) {
            try? FileManager.default.removeItem(at: zipUrl)
        }
        do {
            try Zip.zipFiles(paths: files,
                             zipFilePath: zipUrl,
                             password: nil,
                             compression: .DefaultCompression)
            { progress in
                if progress >= 1 {
                    DispatchQueue.main.async {
                        let vc = UIActivityViewController(activityItems: [zipUrl], applicationActivities: nil)
                        self.mainContainer?.concreteViewController.popoverViewController(viewController: vc, fromSource: sender as? UIView) {
                            self.stopActivityIndicator()
                        }
                    }
                }
            }
        } catch {
            toast("error happen \(error)")
        }
    }

    @objc func onClickAbout(sender _: Any?) {
        navigationController?.pushViewController(AboutUsViewController(), animated: true)
    }

    @objc func onClickShortcuts(sender _: Any?) {
        let vc = PreferenceViewController(style: .setting)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func onClickTheme(sender: Any?) {
        let alertController = UIAlertController(title: localizeStrings("Select Theme"), message: nil, preferredStyle: .actionSheet)
        let manager = Theme.shared
        let current = manager.style
        for i in ThemeStyle.allCases {
            let selected = localizeStrings("selected")
            alertController.addAction(.init(title: i.description + ((current == i) ? selected : ""), style: .default, handler: { _ in
                manager.updateUserPreferredStyle(i, whiteboardStyle: nil)
                self.updateItems()
            }))
        }
        alertController.addAction(.init(title: localizeStrings("Cancel"), style: .cancel, handler: nil))
        if let cell = sender as? SettingTableViewCell {
            popoverViewController(viewController: alertController, fromSource: cell.settingDetailLabel)
        }
    }

    @objc func onClickSecurity(sender _: Any?) {
        navigationController?.pushViewController(SecurityViewController(), animated: true)
    }

    @objc func onClickLanguage(sender: Any?) {
        let alertController = UIAlertController(title: localizeStrings("Select Language"), message: nil, preferredStyle: .actionSheet)
        let currentLanguage = LocaleManager.language
        for l in Language.allCases {
            alertController.addAction(.init(title: l == currentLanguage ? "\(l.name)\(localizeStrings("selected"))" : l.name, style: .default, handler: { _ in
                Bundle.set(language: l)
                self.rebootAndTurnToSetting()
                logger.info("local update \(LocaleManager.languageCode ?? "")")
            }))
        }
        alertController.addAction(.init(title: localizeStrings("Cancel"), style: .cancel, handler: nil))
        if let cell = sender as? SettingTableViewCell {
            popoverViewController(viewController: alertController, fromSource: cell.settingDetailLabel)
        }
    }

    func rebootAndTurnToSetting() {
        guard let window = view.window,
              let scene = window.windowScene else { return }
        SceneManager.shared.reboot(scene: scene)
        guard let root = window.rootViewController else { return }
        let top = UIApplication.shared.topWith(root: root)
        top?.mainContainer?.push(Self())
    }

    @objc func onClickContactUs() {
        navigationController?.pushViewController(ContactUsViewController(), animated: true)
    }

    // MARK: - Lazy

    lazy var logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.borderWidth = commonBorderWidth
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 4
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle("  " + localizeStrings("Logout"), for: .normal)
        button.addTarget(self, action: #selector(onClickLogout), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 0, left: 44, bottom: 0, right: 44)
        button.setImage(UIImage(named: "logout"), for: .normal)

        button.setTraitRelatedBlock { button in
            let color = UIColor.color(light: .red6, dark: .red5)
            button.layer.borderColor = color.resolvedColor(with: button.traitCollection).cgColor
            button.setTitleColor(color.resolvedColor(with: button.traitCollection), for: .normal)
            button.tintColor = color
        }
        return button
    }()

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .color(type: .background)
        view.register(UINib(nibName: String(describing: SettingTableViewCell.self), bundle: nil), forCellReuseIdentifier: cellIdentifier)
        let container = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 40)))
        container.backgroundColor = .color(type: .background)
        container.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        view.separatorStyle = .none
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = container
        view.tableHeaderView = .init(frame: .init(origin: .zero, size: .init(width: 0, height: 12)))
        return view
    }()

    // MARK: - Tableview

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        48
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        24
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        18
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        UIView()
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView(frame: .zero)
        view.backgroundColor = .red
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.text = items[section].title
        label.textColor = .color(type: .text, .weak)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        return view
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        items[section].items.count
    }

    func numberOfSections(in _: UITableView) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let item = items[indexPath.section].items[indexPath.row]
        if item.detail is String, let pairs = item.targetAction {
            pairs.0.performSelector(onMainThread: pairs.1, with: cell, waitUntilDone: true)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! SettingTableViewCell
        cell.iconImageView.image = item.image
        cell.settingTitleLabel.text = item.title
        if let bool = item.detail as? Bool {
            cell.settingDetailLabel.isHidden = true
            cell.switch.isHidden = false
            cell.switch.isOn = bool
            cell.rightArrowView.isHidden = true
            if let pair = item.targetAction {
                cell.switch.addTarget(pair.0, action: pair.1, for: .valueChanged)
            }
        }
        if let description = item.detail as? String {
            cell.rightArrowView.isHidden = false
            cell.settingDetailLabel.isHidden = false
            cell.switch.isHidden = true
            cell.settingDetailLabel.text = description
        }
        return cell
    }
}

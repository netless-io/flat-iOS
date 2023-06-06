//
//  PreferenceViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/11/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Fastboard
import UIKit

let undoRedoPreferenceUpdateNotificaton: Notification.Name = .init("undoRedoShortcutUpdateNotificaton")
let defaultPreferences: [PreferrenceType: Bool] = supportApplePencil() ?
    [.disableDefaultUndoRedo: false, .pencilTail: true] :
    [.disableDefaultUndoRedo: false, .applePencilFollowSystem: true, .pencilTail: true]

class PerferrenceManager {
    static var key: String {
        AuthStore.shared.user!.userUUID + "-shortcuts"
    }

    private init() {
        if let value =
            UserDefaults.standard.value(forKey: Self.key) as? Data,
            let result = try? JSONDecoder().decode([PreferrenceType: Bool].self, from: value)
        {
            // To sync shortcuts
            if result.count != defaultPreferences.count {
                preferences = defaultPreferences
                result.forEach { k, v in
                    updatePreference(type: k, value: v)
                }
            } else {
                preferences = result
            }
            return
        }
        preferences = defaultPreferences
    }

    func updatePreference(type: PreferrenceType, value: Bool) {
        preferences[type] = value
        switch type {
        case .disableDefaultUndoRedo:
            NotificationCenter.default.post(name: undoRedoPreferenceUpdateNotificaton, object: nil, userInfo: ["disable": value])
        case .applePencilFollowSystem:
            FastRoom.followSystemPencilBehavior = value
        case .pencilTail:
            break
        }
        logger.info("update preference \(type), \(value)")
        do {
            let newData = try JSONEncoder().encode(preferences)
            UserDefaults.standard.setValue(newData, forKey: Self.key)
        } catch {
            logger.error("update shortcuts error \(error)")
        }
    }

    func resetPreferences() {
        logger.info("reset preferences")
        UserDefaults.standard.removeObject(forKey: Self.key)
        preferences = defaultPreferences

        if let applePencilFollowSystem = preferences[.applePencilFollowSystem] {
            FastRoom.followSystemPencilBehavior = applePencilFollowSystem
        }
    }

    static let shared = PerferrenceManager()
    private(set) var preferences: [PreferrenceType: Bool]
}

enum PreferrenceType: Codable {
    // 双指轻点 / 三指轻点默认 undo / redo
    case disableDefaultUndoRedo
    case applePencilFollowSystem
    case pencilTail

    var title: String {
        switch self {
        case .disableDefaultUndoRedo:
            return localizeStrings("UndoRedoShortcuts")
        case .applePencilFollowSystem:
            return localizeStrings("ApplePencilShortcuts")
        case .pencilTail:
            return localizeStrings("PencilTail")
        }
    }

    var detail: String {
        switch self {
        case .disableDefaultUndoRedo:
            return localizeStrings("UndoRedoShortcutsDetail")
        case .applePencilFollowSystem:
            return localizeStrings("ApplePencilShortcutsDetail")
        case .pencilTail:
            return localizeStrings("PencilTailDetail")
        }
    }
}

class PreferenceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    enum DisplayItem {
        case preference(PreferrenceType, Bool)
        var title: String {
            switch self {
            case .preference(let t, _): return t.title
            }
        }
        
        var detail: String {
            switch self {
            case .preference(let t, _): return t.detail
            }
        }
    }
    enum Style {
        case setting
        case inClassroom
    }

    let style: Style
    let cellIdentifier = "cellIdentifier"
    let itemHeight: CGFloat = 88
    init(style: Style = .inClassroom) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = .init(width: 0, height: CGFloat(items.count) * itemHeight)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        title = localizeStrings("Preferences")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        switch style {
        case .inClassroom:
            tableView.backgroundColor = .classroomChildBG
        case .setting:
            tableView.backgroundColor = .color(type: .background)
            let container = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 40)))
            container.backgroundColor = .color(type: .background)
            container.addSubview(resetButton)
            resetButton.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }
            tableView.tableFooterView = container
        }
    }

    @objc func onClickReset() {
        showCheckAlert(message: localizeStrings("ResetShortcutsAlert")) { [unowned self] in
            PerferrenceManager.shared.resetPreferences()
            self.updateItems()
        }
    }

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.register(PreferenceTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.separatorStyle = .none
        view.delegate = self
        view.dataSource = self
        view.tableHeaderView = .minHeaderView()
        return view
    }()

    lazy var resetButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.borderWidth = commonBorderWidth
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 4
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle("  " + localizeStrings("ResetPreference"), for: .normal)
        button.addTarget(self, action: #selector(onClickReset), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 0, left: 44, bottom: 0, right: 44)

        button.setTraitRelatedBlock { button in
            button.layer.borderColor = UIColor.color(type: .danger).resolvedColor(with: button.traitCollection).cgColor
            button.setTitleColor(UIColor.color(type: .danger).resolvedColor(with: button.traitCollection), for: .normal)
        }
        return button
    }()

    lazy var items: [DisplayItem] = PerferrenceManager.shared.preferences.map { DisplayItem.preference($0.key, $0.value) }
    
    func updateItems() {
        items = PerferrenceManager.shared.preferences.map { DisplayItem.preference($0.key, $0.value) }
        tableView.reloadData()
    }

    // MARK: - Tableview

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        itemHeight
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! PreferenceTableViewCell
        cell.preferenceTitleLabel.text = item.title
        cell.preferenceDetailLabel.text = item.detail
        switch item {
        case .preference(_, let isOn):
            cell.preferenceSwitch.isHidden = false
            cell.preferenceSwitch.isOn = isOn
        }
        
        switch style {
        case .inClassroom:
            cell.contentView.backgroundColor = .classroomChildBG
        case .setting:
            cell.contentView.backgroundColor = .color(type: .background)
        }
        cell.switchHandler = { [weak self] isOn in
            guard let self else { return }
            if case .preference(let type, _) = item {
                PerferrenceManager.shared.updatePreference(type: type, value: isOn)
            }
            self.updateItems()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
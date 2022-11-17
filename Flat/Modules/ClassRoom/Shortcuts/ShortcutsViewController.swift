//
//  ShortcutsViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/11/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import Fastboard

let undoRedoShortcutsUpdateNotificaton: Notification.Name = .init("undoRedoShortcutUpdateNotificaton")
let defaultShortcuts: [ShortcutsType: Bool] = isCompact() ?
[.disableDefaultUndoRedo: false, .pencilTail: true] :
[.disableDefaultUndoRedo: false, .applePencilFollowSystem: true, .pencilTail: true]
class ShortcutsManager {
    static var key: String {
        AuthStore.shared.user!.userUUID + "-shortcuts"
    }
    
    private init() {
        if let value =
            UserDefaults.standard.value(forKey: Self.key) as? Data,
           let result = try? JSONDecoder().decode([ShortcutsType: Bool].self, from: value)
           {
            // To sync shortcuts
            if result.count != defaultShortcuts.count {
                shortcuts = defaultShortcuts
                result.forEach { k, v in
                    updateShortcuts(type: k, value: v)
                }
            } else {
                shortcuts = result
            }
            return
        }
        shortcuts = defaultShortcuts
    }
    
    func updateShortcuts(type: ShortcutsType, value: Bool) {
        shortcuts[type] = value
        switch type {
        case .disableDefaultUndoRedo:
            NotificationCenter.default.post(name: undoRedoShortcutsUpdateNotificaton, object: nil, userInfo: ["disable": value])
        case .applePencilFollowSystem:
            FastRoom.followSystemPencilBehavior = value
        case .pencilTail:
            break
        }
        logger.info("update shortcuts \(type), \(value)")
        do {
            let newData = try JSONEncoder().encode(shortcuts)
            UserDefaults.standard.setValue(newData, forKey: Self.key)
        }
        catch {
            logger.error("update shortcuts error \(error)")
        }
    }
    
    func resetShortcuts() {
        logger.info("reset shortcuts")
        UserDefaults.standard.removeObject(forKey: Self.key)
        shortcuts = defaultShortcuts
        
        FastRoom.followSystemPencilBehavior = shortcuts[.applePencilFollowSystem]!
    }
    
    static let shared = ShortcutsManager()
    private(set) var shortcuts: [ShortcutsType: Bool]
}

enum ShortcutsType: Codable {
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

class ShortcutsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let cellIdentifier = "cellIdentifier"
    let itemHeight: CGFloat = 88
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        preferredContentSize = .init(width: 0, height: CGFloat(defaultShortcuts.count) * itemHeight)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        title = localizeStrings("Shortcuts")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func onClickReset() {
        showCheckAlert(message: localizeStrings("ResetShortcutsAlert")) { [unowned self] in
            ShortcutsManager.shared.resetShortcuts()
            self.updateItems()
        }
    }
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .classroomChildBG
        view.register(ShortcutsTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        let container = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 40)))
        container.backgroundColor = .color(type: .background)
        container.addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        view.separatorStyle = .none
        view.delegate = self
        view.dataSource = self
        if !(isBeingPresented || presentingViewController != nil) {
            view.tableFooterView = container
        }
        view.tableHeaderView = .minHeaderView()
        return view
    }()
    
    lazy var resetButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.borderWidth = 1
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 4
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle("  " + localizeStrings("ResetShortcuts"), for: .normal)
        button.addTarget(self, action: #selector(onClickReset), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 0, left: 44, bottom: 0, right: 44)
        
        button.setTraitRelatedBlock { button in
            button.layer.borderColor = UIColor.color(type: .danger).resolveDynamicColorPatchiOS13With(button.traitCollection).cgColor
            button.setTitleColor(UIColor.color(type: .danger).resolveDynamicColorPatchiOS13With(button.traitCollection), for: .normal)
        }
        return button
    }()
    
    lazy var items: [(ShortcutsType, Bool)] = ShortcutsManager.shared.shortcuts.map { $0 }
    func updateItems() {
        items = ShortcutsManager.shared.shortcuts.map { $0 }
        tableView.reloadData()
    }
    
    // MARK: - Tableview
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        itemHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ShortcutsTableViewCell
        cell.shortcutsTitleLabel.text = item.0.title
        cell.shortcutsDetailLabel.text = item.0.detail
        cell.shortcutsSwitch.isOn = item.1
        cell.switchHandler = { [weak self] isOn in
            guard let self = self else { return }
            ShortcutsManager.shared.updateShortcuts(type: item.0, value: isOn)
            self.updateItems()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

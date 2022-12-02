//
//  RecordSelectionListViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class RecordSelectionListCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(recordTitleLabel)
        let sbg = UIView()
        sbg.backgroundColor = .blue7
        selectedBackgroundView = sbg
        recordTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var recordTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        return label
    }()
}

class RecordSelectionListViewController: UITableViewController {
    var sections: [(String, Bool)] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var dismissHandler: (()->Void)?
    var clickHandler: ((Int)->Void)?
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismissHandler?()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolBar.frame = view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = toolBar
        tableView.backgroundColor = .clear
        tableView.rowHeight = 44
        tableView.register(RecordSelectionListCell.self, forCellReuseIdentifier: "RecordSelectionListCell")
        tableView.tableHeaderView = headView
    }
    
    lazy var headView: UIView = {
        let view = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 44)))
        
        let titleLabel = UILabel()
        view.addSubview(titleLabel)
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.text = localizeStrings("RecordingList")
        
        let icon = UIImage(systemName: "list.number", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let iconView = UIImageView(image: icon)
        view.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(44)
            make.centerY.equalToSuperview()
        }
        
        view.addLine(direction: .bottom, color: .grey5, width: 1 / UIScreen.main.scale)
        return view
    }()
    
    lazy var toolBar: UIToolbar = {
        let bar = UIToolbar()
        bar.barStyle = .black
        bar.clipsToBounds = true
        return bar
    }()

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordSelectionListCell", for: indexPath) as! RecordSelectionListCell
        let item = sections[indexPath.row]
        cell.recordTitleLabel.text = item.0
        cell.accessoryType = item.1 ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        clickHandler?(indexPath.row)
        sections = sections.enumerated().map { i, e in
            return (e.0, i == indexPath.row)
        }
    }
}

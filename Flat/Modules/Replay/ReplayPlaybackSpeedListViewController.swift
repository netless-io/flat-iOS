//
//  ReplayPlaybackSpeedListViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class ReplayPlaybackSpeedListCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(playbackSpeedLabel)
        let sbg = UIView()
        sbg.backgroundColor = .blue7
        selectedBackgroundView = sbg
        playbackSpeedLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var playbackSpeedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        return label
    }()
}

class ReplayPlaybackSpeedListViewController: UITableViewController {
    var sections: [(Float, Bool)] = [
        (0.75, false),
        (1.0, true),
        (1.5, false),
        (2.0, false),
    ] {
        didSet {
            tableView.reloadData()
        }
    }

    var dismissHandler: (() -> Void)?
    var rateUpdateHandler: ((Float) -> Void)?

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
        tableView.register(ReplayPlaybackSpeedListCell.self, forCellReuseIdentifier: "ReplayPlaybackSpeedListCell")
        preferredContentSize = .init(width: 144, height: 44 * CGFloat(sections.count))
    }

    lazy var toolBar: UIToolbar = {
        let bar = UIToolbar()
        bar.barStyle = .black
        bar.clipsToBounds = true
        return bar
    }()

    // MARK: - Table view data source

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReplayPlaybackSpeedListCell", for: indexPath) as! ReplayPlaybackSpeedListCell
        let item = sections[indexPath.row]
        cell.playbackSpeedLabel.text = String(format: "x %.2f", item.0)
        cell.accessoryType = item.1 ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.row]
        rateUpdateHandler?(item.0)
        sections = sections.enumerated().map { i, e in
            (e.0, i == indexPath.row)
        }
    }
}

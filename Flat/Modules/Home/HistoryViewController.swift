//
//  HistoryViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class HistoryViewController: UIViewController {
    let historyTableViewCellIdentifier = "historyTableViewCellIdentifier"
    
    lazy var list: [RoomBasicInfo] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRooms(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        title = localizeStrings("History")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.refreshControl = .init(frame: .zero)
        tableView.refreshControl?.addTarget(self, action: #selector(onRefresh(_:)), for: .valueChanged)
    }
    
    func removeAt(indexPath: IndexPath) {
        let item = list[indexPath.row]
        
        tableView.beginUpdates()
        list.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .right)
        tableView.endUpdates()
    }
    
    func loadRooms(_ sender: Any?, completion: @escaping ((Error?)->Void) = { _ in }) {
        ApiProvider.shared.request(fromApi: RoomHistoryRequest(page: 1)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let list):
                self.list = list
                completion(nil)
            case.failure(let error):
                completion(error)
            }
        }
    }
    
    @objc func onRefresh(_ sender: UIRefreshControl) {
        loadRooms(sender) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                sender.endRefreshing()
            }
        }
    }

    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.backgroundColor = .whiteBG
        table.showsVerticalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 76
        table.emptyDataSetDelegate = self
        table.emptyDataSetSource = self
        table.register(.init(nibName: String(describing: RoomTableViewCell.self), bundle: nil), forCellReuseIdentifier: historyTableViewCellIdentifier)
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }
        return table
    }()
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        list.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = list[indexPath.row]
        showDeleteAlertWith(message: NSLocalizedString("Delete room record alert", comment: "")) {
            self.showActivityIndicator()
            ApiProvider.shared.request(fromApi: CancelRoomHistoryRequest(roomUUID: item.roomUUID)) { result in
                self.stopActivityIndicator()
                switch result {
                case .failure(let error):
                    self.toast(error.localizedDescription)
                case .success:
                    self.removeAt(indexPath: indexPath)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: historyTableViewCellIdentifier, for: indexPath) as! RoomTableViewCell
        cell.render(info: list[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = list[indexPath.row]
        let vc = RoomDetailViewController(info: item)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - EmptyData
extension HistoryViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        .init(string: localizeStrings("NoHistoryTip"),
              attributes: [
                .foregroundColor: UIColor.color(type: .text),
                    .font: UIFont.systemFont(ofSize: 14)
              ])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "history_empty", in: nil, compatibleWith: traitCollection)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        true
    }
}

//
//  CloudStorageDisplayViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/3/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import Fastboard
import Whiteboard
import DZNEmptyDataSet
import RxSwift
import RxCocoa

let cloudStorageShouldUpdateNotificationName = Notification.Name("cloudStorageShouldUpdateNotificationName")

class CloudStorageDisplayViewController: UIViewController,
                                         UITableViewDelegate,
                                         UITableViewDataSource,
                                         DZNEmptyDataSetSource,
                                         DZNEmptyDataSetDelegate {
    let cellIdentifier = "CloudStorageTableViewCell"
    let container = PageListContainer<StorageFileModel>()
    var loadingMoreRequest: URLSessionDataTask?
    
    // MARK: - LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        taskProgressPolling.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        taskProgressPolling.pause()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadEmptyDataSet()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        observeItemsUpdate()
        observeUpdateNotification()
        observeCanDelete()
        loadData(loadMore: false)
    }
    
    // MARK: - Datas
    @objc func loadFirstPageData() {
        loadingMoreRequest?.cancel()
        loadingMoreRequest = nil
        loadData(loadMore: false)
    }
    
    @discardableResult
    func loadData(loadMore: Bool) -> URLSessionDataTask? {
        let page = loadMore ? container.currentPage + 1 : 1
        return ApiProvider.shared.request(fromApi: StorageListRequest(page: page)) { [weak self] result in
            guard let self = self else { return }
            self.tableView.refreshControl?.endRefreshing()
            switch result {
            case .success(let r):
//                let mb = Int(Float(r.totalUsage) / 1024 / 1024)
//                self.storageUsageLabel.text = NSLocalizedString("Used Capacity", comment: "") + " " + mb.description + " MB"
                self.container.receive(items: r.files, withItemsPage: page)
                if page > 1 {
                    self.loadingMoreRequest = nil
                }
                self.tableView.showLoadedAll(!self.container.items.isEmpty && !self.container.canLoadMore)
            case .failure(let error):
                self.toast(error.localizedDescription)
            }
        }
    }
    
    func deleteItems(_ items: [StorageFileModel]) {
        let request = RemoveFilesRequest(fileUUIDs: items.map { $0.fileUUID })
        
        func executeDelete() {
            showActivityIndicator()
            ApiProvider.shared.request(fromApi: request).mapToVoid()
                .asSingle()
                .subscribe(with: self, onSuccess: { weakSelf, _ in
                    weakSelf.stopActivityIndicator()
                    weakSelf.loadData(loadMore: false)
                }, onFailure: { weakSelf, error in
                    weakSelf.stopActivityIndicator()
                    weakSelf.toast(error.localizedDescription)
                }, onDisposed: { weakSelf in
                    weakSelf.stopActivityIndicator()
                })
                .disposed(by: rx.disposeBag)
        }
        
        showCheckAlert( message: NSLocalizedString("Delete File Alert", comment: "")) {
            executeDelete()
        }
    }
    
    // MARK: - Actions
    func rename(_ item: StorageFileModel) {
        let alert = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
        let ext = String(item.fileName.split(separator: ".").last ?? "")
        alert.addTextField { t in
            t.text = String(item.fileName.split(separator: ".").first ?? "")
        }
        alert.addAction(.init(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: { _ in
            let newName = alert.textFields?[0].text ?? ""
            let newFileName = newName + ".\(ext)"
            let req = RenameFileRequest(fileName: newFileName, fileUUID: item.fileUUID)
            self.showActivityIndicator()
            ApiProvider.shared.request(fromApi: req) { [weak self] result in
                guard let self = self else { return }
                self.stopActivityIndicator()
                switch result {
                case .success:
                    if let index = self.container.items.firstIndex(of: item) {
                        var newItem = self.container.items[index]
                        newItem.fileName = newFileName
                        self.container.items[index] = newItem
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    self.toast(error.localizedDescription)
                }
            }
        }))
        alert.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func onReceiveUpdateNotification() {
        loadFirstPageData()
    }
    
    @objc func onClickEdit(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
        sender.isSelected = !sender.isSelected
    }
    
    @objc func onClickDelete(_ sender: UIButton) {
        guard let tableItems = tableView.indexPathsForSelectedRows, !tableItems.isEmpty else { return }
        let items = tableItems.map { container.items[$0.row] }
        deleteItems(items)
    }
    
    // MARK: - Private
    func observeItemsUpdate() {
        container.itemsUpdateHandler = { [weak self] newItems, _ in
            guard let self = self else { return }
//            let noItemsWhenEdit = newItems.isEmpty && self.tableView.isEditing
//            if noItemsWhenEdit {
//                self.editButton.sendActions(for: .touchUpInside)
//            }
            self.confirmConvertingTasks(withItems: newItems)
            self.tableView.reloadData()
        }
    }
    
    func observeUpdateNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveUpdateNotification), name: cloudStorageShouldUpdateNotificationName, object: nil)
    }
    
    func observeCanDelete() {
        let trigger = Driver.of(Driver.just(()),
                                tableView.rx.itemSelected.asDriver().mapToVoid(),
                                tableView.rx.itemDeselected.asDriver().mapToVoid())
            .merge()
        
        let canDelete = trigger
            .map { [unowned self] _ in
                self.tableView.isEditing &&
                !(self.tableView.indexPathsForSelectedRows ?? [])
                    .isEmpty
            }
        
        canDelete.map { !$0 }
            .drive(deleteAllButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        view.backgroundColor = .color(type: .background)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Converting
    func confirmConvertingTasks(withItems items: [StorageFileModel]) {
        items
            .filter {
                ConvertService.shouldConvertFile(withFile: $0)
            }
            .forEach {
                let uuid = $0.fileUUID
                ConvertService.startConvert(fileUUID: uuid, isWhiteboardProjector: ConvertService.isDynamicPpt(url: $0.fileURL)) { [weak self] r in
                    switch r {
                    case .success(let model):
                        guard let self = self else { return }
                        if let index = self.container.items.firstIndex(where: { $0.fileUUID == uuid }) {
                            self.container.items[index].updateConvert(step: .converting,
                                                                      taskUUID: model.taskUUID,
                                                                      taskToken: model.taskToken)
                            self.configPollingTaskWith(newItems: self.container.items)
                        }
                    case .failure(let error):
                        self?.toast(error.localizedDescription)
                    }
                }
            }
        configPollingTaskWith(newItems: items)
    }
    
    func configPollingTaskWith(newItems: [StorageFileModel]) {
        let itemsShouldPolling = newItems.filter {
            if let info = $0.meta.whiteConverteInfo,
               info.convertStep == .converting,
               $0.taskType != nil {
                return true
            }
            return false
        }
        guard !itemsShouldPolling.isEmpty else { return }
        itemsShouldPolling.forEach {
            guard let payload = $0.meta.whiteConverteInfo else { return }
            let fileUUID = $0.fileUUID
            let taskUUID = payload.taskUUID
            switch $0.resourceType {
            case .projector:
                self.taskProgressPolling.insertProjectorPollingTask(withTaskUUID: taskUUID,
                                                                    token: payload.taskToken,
                                                                    region: .init(rawValue: payload.region.rawValue)) { progress in
                    logger.trace("task projector \(taskUUID) progress \(progress)")
                } result: { [weak self] success, info, error in
                    if let error = error {
                        self?.toast(error.localizedDescription)
                        return
                    }
                    self?.removeConvertingTask(fileUUID: fileUUID, taskUUID: taskUUID, isFinished: info?.status == .finished)
                }
            case .white:
                self.taskProgressPolling.insertV5PollingTask(withTaskUUID: taskUUID,
                                                             token: payload.taskToken,
                                                             region: .init(rawValue: payload.region.rawValue),
                                                             taskType: $0.taskType!) { progress in
                    logger.trace("task v5 \(taskUUID) progress \(progress)")
                } result: { [weak self] success, info, error in
                    if let error = error {
                        self?.toast(error.localizedDescription)
                        return
                    }
                    self?.removeConvertingTask(fileUUID: fileUUID, taskUUID: taskUUID, isFinished: info?.status == .finished)
                }
            default:
                return
            }
        }
        tableView.reloadData()
    }
    
    func removeConvertingTask(fileUUID: String, taskUUID: String, isFinished: Bool) {
        taskProgressPolling.cancelTask(withTaskUUID: taskUUID)
        guard let index = container.items.firstIndex(where: { $0.fileUUID == fileUUID }) else { return }
        let item = container.items[index]
        guard let payload = item.meta.whiteConverteInfo else { return }
        ApiProvider.shared.request(fromApi: FinishConvertRequest(fileUUID: item.fileUUID, region: payload.region)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if isFinished {
                    if let index = self.container.items.firstIndex(where: { $0.fileUUID == fileUUID }){
                        var new = self.container.items[index]
                        new.updateConvert(step: .done)
                        self.container.items[index] = new
                        self.tableView.reloadData()
                    }
                }
            case .failure(let error):
                logger.error("report convert finish error, \(error)")
            }
        }
    }
    
    // MARK: - Lazy
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .color(type: .background)
        view.separatorStyle = .none
        view.register(CloudStorageTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.rowHeight = 70
        view.showsVerticalScrollIndicator = false
        view.allowsMultipleSelectionDuringEditing = true
        view.emptyDataSetSource = self
        view.emptyDataSetDelegate = self
        view.refreshControl = refreshControl
        if #available(iOS 15.0, *) {
            view.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        }
        return view
    }()
    
    lazy var deleteAllButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle(NSLocalizedString("Delete", comment: ""), for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.contentEdgeInsets = .init(top: 16, left: 16, bottom: 16, right: 16)
        button.addTarget(self, action: #selector(onClickDelete), for: .touchUpInside)
        return button
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl(frame: .zero)
        refreshControl.addTarget(self,
                                 action: #selector(loadFirstPageData),
                                 for: .valueChanged)
        return refreshControl
    }()
    
    lazy var taskProgressPolling = WhiteAdvanceConvertProgressPolling()
    
    // MARK: - TableViewDelegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let reachEnd = (indexPath.row) == (self.tableView(tableView, numberOfRowsInSection: 0) - 1)
        if reachEnd, container.canLoadMore, loadingMoreRequest == nil {
            loadingMoreRequest = loadData(loadMore: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let items = [container.items[indexPath.row]]
        deleteItems(items)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    // MARK: - TableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        container.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CloudStorageTableViewCell
        let item = container.items[indexPath.row]
        cell.iconImage.image = UIImage(named: item.fileType.iconImageName)
        cell.fileNameLabel.text = item.fileName
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateStr = formatter.string(from: item.createAt)
        cell.sizeAndTimeLabel.text = dateStr + "   " + item.fileSizeDescription
        let selBgView = UIView()
        selBgView.backgroundColor = .color(type: .background)
        cell.selectedBackgroundView = selBgView
        if item.converting {
            cell.startConvertingAnimation()
        } else {
            cell.stopConvertingAnimation()
        }
        return cell
    }
    
    // MARK: - EmptyData
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        .init(string: NSLocalizedString("EmptyCloudTip", comment: ""), attributes: [
            .foregroundColor: UIColor.color(type: .text),
            .font: UIFont.systemFont(ofSize: 14)
        ])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        UIImage(named: "cloud_empty", in: nil, compatibleWith: traitCollection)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        true
    }
}

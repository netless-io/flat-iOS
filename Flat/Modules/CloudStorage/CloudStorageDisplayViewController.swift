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
        taskProgressPolling.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
                let mb = Int(Float(r.totalUsage) / 1024 / 1024)
                self.storageUsageLabel.text = NSLocalizedString("Used Capacity", comment: "") + " " + mb.description + " MB"
                self.container.receive(items: r.files, withItemsPage: page)
                if page > 1 {
                    self.loadingMoreRequest = nil
                }
            case .failure(let error):
                self.toast(error.localizedDescription)
            }
        }
    }
    
    func deleteItems(_ items: [StorageFileModel]) {
        let externalFileUUIDs = items.filter { $0.external }.map { $0.fileUUID }
        let internalFileUUIDs = items.filter { !$0.external }.map { $0.fileUUID }
        let externalRequest = RemoveFilesRequest(fileUUIDs: externalFileUUIDs, external: true)
        let internalRequest = RemoveFilesRequest(fileUUIDs: internalFileUUIDs, external: false)
        let externalR: Observable<Void> = externalFileUUIDs.isEmpty ? .just(()) : ApiProvider.shared.request(fromApi: externalRequest).mapToVoid()
        let internalR: Observable<Void> = internalFileUUIDs.isEmpty ? .just(()) : ApiProvider.shared.request(fromApi: internalRequest).mapToVoid()
        
        func executeDelete() {
            showActivityIndicator()
            externalR
                .flatMap { internalR }
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
            let req = RenameFileRequest(fileName: newFileName, fileUUID: item.fileUUID, external: item.external)
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
            let noItemsWhenEdit = newItems.isEmpty && self.tableView.isEditing
            if noItemsWhenEdit {
                self.editButton.sendActions(for: .touchUpInside)
            }
            self.confirmConvertingTasks(withItems: newItems)
            self.tableView.reloadData()
        }
    }
    
    func observeUpdateNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveUpdateNotification), name: cloudStorageShouldUpdateNotificationName, object: nil)
    }
    
    func observeCanDelete() {
        let trigger = Driver.of(Driver.just(()),
                                editButton.rx.tap.asDriver().mapToVoid(),
                                tableView.rx.itemSelected.asDriver().mapToVoid())
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
        
        canDelete
            .drive(storageUsageLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        view.backgroundColor = .whiteBG
        view.addSubview(mainStackView)
        mainStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
        }
        mainStackView.addArrangedSubview(headView)
        mainStackView.addArrangedSubview(tableView)
        headView.snp.makeConstraints { make in
            make.height.equalTo(46)
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
                            self.container.items[index].convertStep = .converting
                            self.container.items[index].taskUUID = model.taskUUID
                            self.container.items[index].taskToken = model.taskToken
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
            $0.convertStep == .converting && $0.taskType != nil
        }
        guard !itemsShouldPolling.isEmpty else { return }
        itemsShouldPolling.forEach {
            let id = $0.taskUUID
            switch $0.resourceType {
            case .projector:
                self.taskProgressPolling.insertProjectorPollingTask(withTaskUUID: id,
                                                                    token: $0.taskToken,
                                                                    region: .init(rawValue: $0.region.rawValue)) { progress in
                    logger.trace("task projector \(id) progress \(progress)")
                } result: { [weak self] success, info, error in
                    if let error = error {
                        self?.toast(error.localizedDescription)
                        return
                    }
                    self?.removeConvertingTask(uuid: id, isFinished: info?.status == .finished)
                }
            case .white:
                self.taskProgressPolling.insertV5PollingTask(withTaskUUID: id,
                                                             token: $0.taskToken,
                                                             region: .init(rawValue: $0.region.rawValue),
                                                             taskType: $0.taskType!) { progress in
                    logger.trace("task v5 \(id) progress \(progress)")
                } result: { [weak self] success, info, error in
                    if let error = error {
                        self?.toast(error.localizedDescription)
                        return
                    }
                    self?.removeConvertingTask(uuid: id, isFinished: info?.status == .finished)
                }
            default:
                return
            }
        }
        tableView.reloadData()
    }
    
    func removeConvertingTask(uuid: String, isFinished: Bool) {
        taskProgressPolling.cancelTask(withTaskUUID: uuid)
        if let index = container.items.firstIndex(where: { $0.taskUUID == uuid }) {
            let item = container.items[index]
            ApiProvider.shared.request(fromApi: FinishConvertRequest(fileUUID: item.fileUUID, region: item.region)) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    if isFinished {
                        if let index = self.container.items.firstIndex(where: { $0.taskUUID == uuid }){
                            var new = self.container.items[index]
                            new.convertStep = .done
                            self.container.items[index] = new
                            self.tableView.reloadData()
                        }
                    }
                case .failure(let error):
                    logger.error("report convert finish error, \(error)")
                }
            }
        }
    }
    
    // MARK: - Lazy
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .whiteBG
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(CloudStorageTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.rowHeight = 68
        view.showsVerticalScrollIndicator = false
        view.allowsMultipleSelectionDuringEditing = true
        view.emptyDataSetSource = self
        view.emptyDataSetDelegate = self
        view.refreshControl = refreshControl
        return view
    }()
    
    lazy var mainStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        return view
    }()
    
    lazy var headView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.lightBlueBar
        view.addSubview(storageUsageLabel)
        view.addSubview(editButton)
        view.addSubview(deleteAllButton)
        deleteAllButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        storageUsageLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(editButton.snp.left).inset(10)
        }
        editButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
    lazy var storageUsageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 14)
        label.textColor = .subText
        return label
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
    
    lazy var editButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)
        button.setTitle(NSLocalizedString("Finish", comment: ""), for: .selected)
        button.setImage(UIImage(named: "edit"), for: .normal)
        button.setImage(UIImage.imageWith(color: .clear), for: .selected)
        button.setTitleColor(.brandColor, for: .normal)
        button.tintColor = .brandColor
        button.adjustsImageWhenHighlighted = false
        button.contentEdgeInsets = .init(top: 16, left: 16, bottom: 16, right: 16)
        button.addTarget(self, action: #selector(onClickEdit), for: .touchUpInside)
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
        selBgView.backgroundColor = .whiteBG
        cell.selectedBackgroundView = selBgView
        if item.convertStep == .converting {
            cell.startConvertingAnimation()
        } else {
            cell.stopConvertingAnimation()
        }
        return cell
    }
    
    // MARK: - EmptyData
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        .init(string: NSLocalizedString("EmptyCloudTip", comment: ""), attributes: [
            .foregroundColor: UIColor.subText,
            .font: UIFont.systemFont(ofSize: 14)
        ])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        UIImage(named: "cloud_empty", in: nil, compatibleWith: traitCollection)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        true
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        0
    }
}

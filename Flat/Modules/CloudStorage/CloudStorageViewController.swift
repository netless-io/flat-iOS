//
//  CloudStorageViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import QuickLook
import Kingfisher
import AVKit
import RxCocoa
import RxSwift
import SafariServices
import EmptyDataSet_Swift
import Whiteboard

let cloudStorageShouldUpdateNotificationName = Notification.Name("cloudStorageShouldUpdateNotificationName")

class CloudStorageViewController: UIViewController {
    let cellIdentifier = "CloudStorageTableViewCell"
    let container = PageListContainer<StorageFileModel>()
    var loadingMoreRequest: URLSessionDataTask?

    var previewingUUID: String? {
        didSet {
            if let newId = previewingUUID, let newIndex = container.items.firstIndex(where: { $0.fileUUID == newId}) {
                tableView.reloadRows(at: [IndexPath(row: newIndex, section: 0)], with: .none)
            }
            if let oldId = oldValue, let oldIndex = container.items.firstIndex(where: { $0.fileUUID == oldId}) {
                tableView.reloadRows(at: [IndexPath(row: oldIndex, section: 0)], with: .none)
            }
        }
    }
    
    weak var previewingController: CustomPreviewViewController?
    var currentPreview: AnyPreview?
    
    // MARK: - LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        taskProgressPolling.startPolling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        taskProgressPolling.pausePolling()
    }
    
    deinit {
        cleanPreviewResource()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = NSLocalizedString("Cloud Storage", comment: "")
        setupViews()
        loadData(loadMore: false)
        container.itemsUpdateHandler = { [weak self] items, _ in
            guard let self = self else { return }
            if items.isEmpty, self.tableView.isEditing {
                self.editButton.sendActions(for: .touchUpInside)
            }
            self.confirmConvertingTasks(withItems: items)
            self.tableView.reloadData()
        }
        observe()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadEmptyDataSet()
    }
    
    // MARK: - Actions
    @objc func onClickAdd() {
        let vc = UploadHomeViewController()
        mainContainer?.push(vc)
    }
    
    @objc func loadFirstPageData() {
        loadingMoreRequest?.cancel()
        loadingMoreRequest = nil
        loadData(loadMore: false)
    }
    
    @objc func onReceiveUpdateNotification() {
        loadFirstPageData()
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
    
    @objc func onClickEdit(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
        sender.isSelected = !sender.isSelected
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
    
    @objc func onClickDelete(_ sender: UIButton) {
        guard let tableItems = tableView.indexPathsForSelectedRows, !tableItems.isEmpty else { return }
        let items = tableItems.map { container.items[$0.row] }
        deleteItems(items)
    }
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .whiteBG
        navigationItem.rightBarButtonItem = .init(image: UIImage(named: "storage_add"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(onClickAdd))
        view.addSubview(headView)
        view.addSubview(tableView)
        headView.snp.makeConstraints { make in
            make.left.right.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(46)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headView.snp.bottom)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        let refreshControl = UIRefreshControl(frame: .zero)
        refreshControl.addTarget(self, action: #selector(loadFirstPageData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    func confirmConvertingTasks(withItems items: [StorageFileModel]) {
        items
            .filter {
                ConvertService.shouldConvertFile(withFile: $0)
            }
            .forEach {
                let uuid = $0.fileUUID
                ConvertService.startConvert(fileUUID: uuid) { [weak self] r in
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
            self.taskProgressPolling.insertPollingTask(withTaskUUID: $0.taskUUID,
                                                       token: $0.taskToken,
                                                       region: .init(rawValue: $0.region.rawValue),
                                                       taskType: $0.taskType!) { progress, info in
                print("task \(info?.uuid ?? "") progress \(progress)")
            } result: { [weak self] success, info, error in
                if let error = error {
                    self?.toast(error.localizedDescription)
                    return
                }
                guard let info = info else { return }
                self?.removeConvertingTask(fromTaskUUID: info.uuid, status: info.status)
            }
        }
        tableView.reloadData()
    }
    
    func removeConvertingTask(fromTaskUUID uuid: String, status: WhiteConvertStatusV5) {
        taskProgressPolling.cancelPollingTask(withTaskUUID: uuid)
        
        let isConvertSuccess = status == .finished
        if let index = container.items.firstIndex(where: { $0.taskUUID == uuid }) {
            let item = container.items[index]
            ApiProvider.shared.request(fromApi: FinishConvertRequest(fileUUID: item.fileUUID, region: item.region)) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    if isConvertSuccess {
                        if let index = self.container.items.firstIndex(where: { $0.taskUUID == uuid }){
                            var new = self.container.items[index]
                            new.convertStep = .done
                            self.container.items[index] = new
                            self.tableView.reloadData()
                        }
                    }
                case .failure(let error):
                    print("report convert finish error, \(error)")
                }
            }
        }
    }
    
    func observe() {
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveUpdateNotification), name: cloudStorageShouldUpdateNotificationName, object: nil)
        
        let trigger = Driver.of(
            Driver.just(()),
            editButton.rx.tap.asDriver().mapToVoid(),
            tableView.rx.itemSelected.asDriver().mapToVoid())
            .merge()
        
        let canDelete = trigger
            .map { [unowned self] _ in
                self.tableView.isEditing && !(self.tableView.indexPathsForSelectedRows ?? []).isEmpty
            }
        
        canDelete.map { !$0 }
            .drive(deleteAllButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        canDelete
            .drive(storageUsageLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
    }
    
    func share(_ item: StorageFileModel) {
        guard let index = container.items.firstIndex(of: item) else { return }
        let cell = tableView.cellForRow(at: .init(row: index, section: 0))
        let vc = UIActivityViewController(activityItems: [item.fileURL], applicationActivities: nil)
        mainContainer?.concreteViewController.popoverViewController(viewController: vc, fromSource: cell)
    }
    
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
    
    func preview(_ item: StorageFileModel) {
        if let _ = previewingController {
            mainContainer?.removeTop()
        }
        cleanPreviewResource()
        previewingUUID = item.fileUUID
        let fileExtension = String(item.fileName.split(separator: ".").last ?? "")
        switch item.fileType {
        case .video:
            let vc = CustomAVPlayerViewController()
            let player = AVPlayer(url: item.fileURL)
            vc.dismissHandler = { [weak self] in
                self?.cleanPreviewResource()
            }
            vc.player = player
            player.play()
            mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
        case .img:
            showActivityIndicator()
            KingfisherManager.shared.retrieveImageDiskCachePath(fromURL: item.fileURL) { [weak self] result in
                DispatchQueue.main.async {
                    self?.stopActivityIndicator()
                    switch result {
                    case .success(let path):
                        self?.previewLocalFileUrlPath(path,
                                                      fileExtension: fileExtension,
                                                      fileName: item.fileName)
                    case .failure(let error):
                        self?.toast(error.localizedDescription)
                    }
                }
            }
        default:
            // Preview dynamic with web preview
            if ConvertService.convertingTaskTypeFor(url: item.fileURL) == .dynamic {
                let formatURL = item.fileURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
                let link = Env().webBaseURL + "/preview/\(formatURL)/\(item.taskToken)/\(item.taskUUID)/\(item.region.rawValue)/"
                if let url = URL(string: link) {
                    let config = SFSafariViewController.Configuration()
                    config.barCollapsingEnabled = true
                    config.entersReaderIfAvailable = false
                    let vc = SFSafariViewController(url: url, configuration: config)
                    vc.delegate = self
                    vc.dismissButtonStyle = .close
                    vc.title = item.fileName
                    mainContainer?.pushOnSplitPresentOnCompact(vc)
                    return
                }
            }
            
            showActivityIndicator()
            let request = URLRequest(url: item.fileURL,
                                     cachePolicy: .returnCacheDataElseLoad,
                                     timeoutInterval: 60)
            let task = URLSession.shared.downloadTask(with: request) { [weak self] targetUrl, response, error in
                DispatchQueue.main.async {
                    self?.stopActivityIndicator()
                }
                guard error == nil else {
                    self?.toast(error!.localizedDescription)
                    return
                }
                guard let url = targetUrl else {
                    self?.toast("download fail")
                    return
                }
                var tempURL = FileManager.default.temporaryDirectory
                tempURL.appendPathComponent(UUID().uuidString)
                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                }
                catch {
                    DispatchQueue.main.async {
                        self?.toast(error.localizedDescription)
                    }
                }
                DispatchQueue.main.async {
                    self?.previewLocalFileUrlPath(tempURL.path,
                                                  fileExtension: fileExtension,
                                                  fileName: item.fileName)
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
            task.resume()
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
    
    lazy var taskProgressPolling = WhiteConverterV5()
}

extension CloudStorageViewController: UITableViewDelegate, UITableViewDataSource {
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
        cell.addImage.isHidden = true
        let selBgView = UIView()
        selBgView.backgroundColor = .whiteBG
        cell.selectedBackgroundView = selBgView
        if item.convertStep == .converting {
            cell.startConvertingAnimation()
        } else {
            cell.stopConvertingAnimation()
        }
        let isPreviewing = item.fileUUID == previewingUUID
        cell.contentView.backgroundColor = isPreviewing ? .controlSelectedBG : .whiteBG
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let items = [container.items[indexPath.row]]
        deleteItems(items)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        container.items.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let reachEnd = (indexPath.row) == (self.tableView(tableView, numberOfRowsInSection: 0) - 1)
        if reachEnd, container.canLoadMore, loadingMoreRequest == nil {
            loadingMoreRequest = loadData(loadMore: true)
        }
    }
    
    func previewLocalFileUrlPath(_ path: String,
                                 fileExtension: String,
                                 fileName: String) {
        var tempURL = FileManager.default.temporaryDirectory
        tempURL.appendPathComponent(UUID().uuidString + ".\(fileExtension)")
        do {
            try FileManager.default.copyItem(atPath: path, toPath: tempURL.path)
            let previewItem = AnyPreview(previewItemURL: URL(fileURLWithPath: tempURL.path), title: fileName)
            currentPreview = previewItem
            let vc = CustomPreviewViewController()
            self.previewingController = vc
            vc.dataSource = self
            vc.delegate = self
            vc.clickBackHandler = { [weak self] in
                self?.cleanPreviewResource()
            }
            mainContainer?.pushOnSplitPresentOnCompact(vc)
        }
        catch {
            print(error)
            toast(error.localizedDescription)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let item = container.items[indexPath.row]
        guard item.usable else { return }
        
        let cell = tableView.cellForRow(at: indexPath)
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(.init(title: NSLocalizedString("Preview", comment: ""), style: .default, handler: { [unowned self] _ in
            if item.convertStep == .converting {
                self.toast(NSLocalizedString("FileIsConverting", comment: ""))
                return
            }
            self.preview(item)
        }))
        alertVC.addAction(.init(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { [unowned self] _ in
            self.rename(item)
        }))
        alertVC.addAction(.init(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { [unowned self] _ in
            self.share(item)
        }))
        alertVC.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        popoverViewController(viewController: alertVC, fromSource: cell)
    }
}

extension CloudStorageViewController: QLPreviewControllerDelegate {
    func cleanPreviewResource() {
        previewingUUID = nil
        if let url = currentPreview?.previewItemURL {
            do {
                try FileManager.default.removeItem(at: url)
            }
            catch {
                print("remove preview item fail")
            }
        }
        currentPreview = nil
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        cleanPreviewResource()
    }
}

extension CloudStorageViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        currentPreview == nil ? 0 : 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        currentPreview!
    }
}

extension CloudStorageViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        mainContainer?.removeTop()
        previewingUUID = nil
    }
}

// MARK: - EmptyData
extension CloudStorageViewController: EmptyDataSetDelegate, EmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        .init(string: NSLocalizedString("EmptyCloudTip", comment: ""), attributes: [
            .foregroundColor: UIColor.subText,
            .font: UIFont.systemFont(ofSize: 14)
        ])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        UIImage(named: "cloud_empty")
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        true
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        0
    }
}

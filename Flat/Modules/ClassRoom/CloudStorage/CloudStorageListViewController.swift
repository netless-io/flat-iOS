//
//  CloudStorageListViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import Whiteboard
import Kingfisher
import RxSwift
import EmptyDataSet_Swift

class CloudStorageListViewController: UIViewController {
    enum CloudStorageFileContent {
        case image(url: URL, image: UIImage)
        /// video or music
        case media(url: URL, title: String)
        /// pdf, doc or ppt
        case multiPages(pages: [(url: URL, preview: URL, size: CGSize)], title: String)
        /// pptx
        case pptx(pages: [(url: URL, preview: URL, size: CGSize)], title: String)
    }
    
    var fileSelectTask: StorageFileModel? {
        didSet {
            if let oldIndex = container.items.firstIndex(where: { $0 == oldValue }) {
                tableView.reloadRows(at: [.init(row: oldIndex, section: 0)], with: .fade)
            }
            
            if let index = container.items.firstIndex(where: { $0 == fileSelectTask }) {
                tableView.reloadRows(at: [.init(row: index, section: 0)], with: .fade)
            }
        }
    }
    var fileContentSelectedHandler: ((CloudStorageFileContent)->Void)?
    
    let cellIdentifier = "CloudStorageTableViewCell"
    let container = PageListContainer<StorageFileModel>()
    var loadingMoreRequest: URLSessionDataTask?
    
    var pollingDisposable: Disposable?
    var convertingItems: [StorageFileModel] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        taskProgressPolling.startPolling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        taskProgressPolling.pausePolling()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadEmptyDataSet()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadData(loadMore: false)
        container.itemsUpdateHandler = { [weak self] items, _ in
            self?.confirmConvertingTasks(withItems: items)
            self?.tableView.reloadData()
        }
    }

    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .whiteBG
        view.addSubview(tableView)
        view.addSubview(topView)
        let topViewHeight: CGFloat = 34
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(topViewHeight)
        }
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets.init(top: topViewHeight, left: 0, bottom: 0, right: 0))
        }
        
        let refreshControl = UIRefreshControl(frame: .zero)
        refreshControl.addTarget(self, action: #selector(onRefreshControl), for: .valueChanged)
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
        print("remove item \(uuid)")
        convertingItems.removeAll(where: { c in
            return uuid == c.taskUUID
        })
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
    
    @objc func onRefreshControl() {
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
                self.container.receive(items: r.files, withItemsPage: page)
                if page > 1 {
                    self.loadingMoreRequest = nil
                }
            case .failure(let error):
                self.toast(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Lazy
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .whiteBG
        let topLabel = UILabel(frame: .zero)
        topLabel.text = NSLocalizedString("Cloud Storage", comment: "")
        topLabel.textColor = .text
        topLabel.font = .systemFont(ofSize: 12, weight: .medium)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
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
        view.emptyDataSetSource = self
        view.emptyDataSetDelegate = self
        return view
    }()
    
    lazy var taskProgressPolling = WhiteConverterV5()
}

extension CloudStorageListViewController: UITableViewDelegate, UITableViewDataSource {
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
        let isProcessing = item == fileSelectTask
        if isProcessing {
            cell.iconImage.alpha = 0
            cell.updateActivityAnimate(true)
            cell.contentView.alpha = 1
        } else {
            cell.iconImage.alpha = 1
            cell.updateActivityAnimate(false)
            cell.contentView.alpha = item.usable ? 1 : 0.5
        }
        if item.convertStep == .converting {
            cell.startConvertingAnimation()
        } else {
            cell.stopConvertingAnimation()
        }
        return cell
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = container.items[indexPath.row]
        switch item.convertStep {
        case .converting:
            toast(NSLocalizedString("FileIsConverting", comment: ""))
            return
        case .failed:
            toast(NSLocalizedString("FileConvertFailed", comment: ""))
            return
        default:
            break
        }
        guard item.usable else { return }
        guard fileSelectTask == nil else {
            toast("waiting for previous file insert")
            return
        }
        
        switch item.fileType {
        case .img:
            fileSelectTask = item
            KingfisherManager.shared.retrieveImage(with: item.fileURL) { [weak self] result in
                self?.fileSelectTask = nil
                switch result {
                case .success(let r):
                    self?.fileContentSelectedHandler?(.image(url: item.fileURL, image: r.image))
                case .failure(let error):
                    self?.toast(error.localizedDescription)
                }
            }
        case .video, .music:
            fileContentSelectedHandler?(.media(url: item.fileURL, title: item.fileName))
        case .pdf, .ppt, .word:
            guard let taskType = item.taskType else {
                toast("can't get the task type")
                return
            }
            fileSelectTask = item
            WhiteConverterV5.checkProgress(withTaskUUID: item.taskUUID,
                                           token: item.taskToken,
                                           region: .init(rawValue: item.region.rawValue),
                                           taskType: taskType) { [weak self] info, error in
                self?.fileSelectTask = nil
                if let error = error {
                    self?.toast(error.localizedDescription)
                    return
                }
                guard let info = info else { return }
                switch info.status {
                case .finished:
                    let pages = info.progress?.convertedFileList.compactMap { item -> (URL, URL, CGSize)? in
                        guard let url = URL(string: item.src)
                        else { return nil }
                        let preview = URL(string: item.previewURL) ?? url
                        return (url, preview, CGSize(width: item.width, height: item.height))
                    }
                    if let pages = pages {
                        if item.fileName.hasSuffix("pptx") {
                            self?.fileContentSelectedHandler?(.pptx(pages: pages, title: item.fileName))
                        } else {
                            self?.fileContentSelectedHandler?(.multiPages(pages: pages, title: item.fileName))
                        }
                    }
                default:
                    self?.toast(NSLocalizedString("File not ready", comment: ""))
                }
            }
            return
        case .unknown:
            toast("file type not defined")
        }
    }
}

// MARK: - EmptyData
extension CloudStorageListViewController: EmptyDataSetDelegate, EmptyDataSetSource {
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

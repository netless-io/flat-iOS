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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadData(loadMore: false)
        container.itemsUpdateHandler = { [weak self] _, _ in
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
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(CloudStorageTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.rowHeight = 68
        view.showsVerticalScrollIndicator = false
        return view
    }()
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
            let req = ConversionTaskProgressRequest(uuid: item.taskUUID,
                                                    type: taskType,
                                                    token: item.taskToken)
            ApiProvider.shared.request(fromApi: req) { [weak self] result in
                guard let self = self else { return }
                self.fileSelectTask = nil
                switch result {
                case .success(let detail):
                    switch detail.status {
                    case .finished:
                        let pages: [(URL, URL, CGSize)] = detail.progress.convertedFileList.map { item -> (URL, URL, CGSize) in
                            return (item.conversionFileUrl, item.preview ?? item.conversionFileUrl, CGSize(width: item.width, height: item.height))
                        }
                        if item.fileName.hasSuffix("pptx") {
                            self.fileContentSelectedHandler?(.pptx(pages: pages, title: item.fileName))
                        } else {
                            self.fileContentSelectedHandler?(.multiPages(pages: pages, title: item.fileName))
                        }
                    default:
                        self.toast("file not ready")
                    }
                case .failure(let error):
                    self.toast(error.localizedDescription)
                }
            }
        case .unknown:
            toast("file type not defined")
        }
    }
}

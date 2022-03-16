//
//  CloudStorageInClassViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/3/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import Whiteboard
import Kingfisher

class CloudStorageInClassViewController: CloudStorageDisplayViewController {
    enum CloudStorageFileContent {
        case image(url: URL, image: UIImage)
        /// video or music
        case media(url: URL, title: String)
        /// pdf, doc or ppt
        case multiPages(pages: [WhitePptPage], title: String)
        /// pptx
        case pptx(pages: [WhitePptPage], title: String)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainStackView.insertArrangedSubview(topView, at: 0)
        topView.snp.makeConstraints { make in
            make.height.equalTo(34)
        }
        
        // Update default style
        editButton.isHidden = true
        storageUsageLabel.font = .systemFont(ofSize: 12)
        storageUsageLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(8)
        }
        headView.snp.remakeConstraints { make in
            make.height.equalTo(34)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = super.tableView(tableView, cellForRowAt: indexPath) as?
                CloudStorageTableViewCell
        else { fatalError() }
        
        cell.addImage.isHidden = false
        let item = container.items[indexPath.row]
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else { return }
        
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
                    let pages = info.progress?.convertedFileList.compactMap { return $0 } ?? []
                    if item.fileName.hasSuffix("pptx") {
                        self?.fileContentSelectedHandler?(.pptx(pages: pages, title: item.fileName))
                    } else {
                        self?.fileContentSelectedHandler?(.multiPages(pages: pages, title: item.fileName))
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
}

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
        /// project
        case projectorPptx(uuid: String, prefix: String, title: String)
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        addButton.setImage(UIImage(named: "storage_add_small"), for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = .classroomChildBG
        tableView.removeFromSuperview()
        view.addSubview(topView)
        view.addSubview(tableView)
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(40)
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset((UIEdgeInsets(top: 34, left: 0, bottom: 0, right: 0)))
        }
        setupAddButton()
        
        preferredContentSize = .init(width: UIScreen.main.bounds.width / 2, height: 560)
    }
        
    
    func uploadActionFor(type: UploadType) {
        UploadUtility.shared.start(uploadType: type, fromViewController: self, delegate: self, presentStyle: .popOver(parent: self, source: self.addButton))
    }
    
    func setupAddButton() {
        if #available(iOS 14.0, *) {
            let actions = UploadType.allCases.map { type in
                UIAction(title: type.title, image: UIImage(named: type.imageName)?.withTintColor(.color(type: .text, .strong), renderingMode: .alwaysOriginal)) { _ in
                    self.uploadActionFor(type: type)
                }
            }
            addButton.menu = .init(title: "", children: actions)
            addButton.showsMenuAsPrimaryAction = true
        } else {
            addButton.addTarget(self, action: #selector(onClickAdd(_:)), for: .touchUpInside)
        }
    }
    
    @objc func onClickAdd(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Upload", comment: ""), message: nil, preferredStyle: .actionSheet)
        UploadType.allCases.forEach { type in
            alert.addAction(.init(title: type.title, style: .default, handler: { [weak self] _ in self?.uploadActionFor(type: type)}))
        }
        alert.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        popoverViewController(viewController: alert, fromSource: sender)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = super.tableView(tableView, cellForRowAt: indexPath) as?
                CloudStorageTableViewCell
        else { fatalError() }
        
        cell.selectionView.isHidden = true
        cell.backgroundColor = .classroomChildBG
        cell.contentView.backgroundColor = .classroomChildBG
        cell.fileNameLabel.textColor = .color(type: .text)
        cell.sizeAndTimeLabel.textColor = .init(hexString: "#B7BBC1")
        cell.rightArrowImageView.isHidden = false
        
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

            if item.resourceType == .projector {
                WhiteProjectorPolling.checkProgress(withTaskUUID: item.taskUUID, token: item.taskToken, region: .init(rawValue: item.region.rawValue)) { [weak self] info, error in
                    self?.fileSelectTask = nil
                    if let error = error {
                        self?.toast(error.localizedDescription)
                        return
                    }
                    guard let info = info else { return }
                    switch info.status {
                    case .finished:
                        self?.fileContentSelectedHandler?(.projectorPptx(uuid: info.uuid, prefix: info.prefix, title: item.fileName))
                    default:
                        self?.toast(NSLocalizedString("File not ready", comment: ""))
                    }
                }
            } else {
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
            }
        case .unknown:
            toast("file type not defined")
        }
    }
    
    // MARK: - Lazy
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .classroomChildBG
        
        let leftIcon = UIImageView(image: UIImage(named: "classroom_cloud")?.tintColor(.color(type: .text, .strong)))
        view.traitCollectionUpdateHandler = { [weak leftIcon] _ in
            leftIcon?.image = UIImage(named: "classroom_cloud")?.tintColor(.color(type: .text, .strong))
        }
        leftIcon.contentMode = .center
        view.addSubview(leftIcon)
        leftIcon.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(40)
        }
        
        let topLabel = UILabel(frame: .zero)
        topLabel.text = localizeStrings("Cloud Storage")
        topLabel.textColor = .color(type: .text, .strong)
        topLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(40)
        }
        let line = UIView()
        line.backgroundColor = .borderColor
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1/UIScreen.main.scale)
        }
        view.addSubview(addFileStackView)
        addFileStackView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        return view
    }()
    
    lazy var addFileStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.uploadingActivity, self.addButton])
        view.axis = .horizontal
        addButton.snp.makeConstraints { make in
            make.width.equalTo(66)
        }
        uploadingActivity.transform = .init(translationX: 18, y: 0)
        return view
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "storage_add_small")?.tintColor(.color(type: .text)), for: .normal)
        button.traitCollectionUpdateHandler = { [weak button] _ in
            button?.setImage(UIImage(named: "storage_add_small")?.tintColor(.color(type: .text)), for: .normal)
        }
        return button
    }()
    
    lazy var uploadingActivity: UIActivityIndicatorView = {
        let view: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            view = UIActivityIndicatorView(style: .medium)
        } else {
            view = UIActivityIndicatorView(style: .gray)
        }
        view.hidesWhenStopped = true
        return view
    }()
    
    func update(isUploading: Bool) {
        addButton.isEnabled = !isUploading
        if isUploading {
            uploadingActivity.startAnimating()
        } else {
            uploadingActivity.stopAnimating()
        }
    }
    
    func uploadFile(url: URL, region: FlatRegion, shouldAccessingSecurityScopedResource: Bool) {
        do {
            let result = try UploadService.shared
                .createUploadTaskFrom(fileURL: url,
                                      region: region,
                                      shouldAccessingSecurityScopedResource: shouldAccessingSecurityScopedResource)
            result.task.do(onSuccess: { fillUUID in
                if ConvertService.isFileConvertible(withFileURL: url) {
                    ConvertService.startConvert(fileUUID: fillUUID, isWhiteboardProjector: ConvertService.isDynamicPpt(url: url)) { [weak self] result in
                        switch result {
                        case .success:
                            NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil)
                        case .failure(let error):
                            self?.toast(error.localizedDescription)
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil)
                }
            }).subscribe().disposed(by: rx.disposeBag)
                
            
            result.tracker
                .subscribe(with: self) { weakSelf,status in
                    switch status {
                    case .error(let error):
                        weakSelf.update(isUploading: false)
                        weakSelf.toast(error.localizedDescription)
                    case .cancel:
                        weakSelf.update(isUploading: false)
                    case .idle:
                        return
                    case .preparing:
                        return
                    case .prepareFinish:
                        return
                    case .uploading:
                        return
                    case .uploadFinish:
                        return
                    case .reporting:
                        return
                    case .reportFinish:
                        return
                    case .finish:
                        weakSelf.update(isUploading: false)
                    }
                } onError: { weakSelf,error in
                    weakSelf.update(isUploading: false)
                    weakSelf.toast(error.localizedDescription)
                } onCompleted: { weakSelf in
                    weakSelf.update(isUploading: false)
                } onDisposed: { _ in
                    return
                }
                .disposed(by: rx.disposeBag)
        }
        catch {
            logger.error("error create task \(error)")
            toast("error create task \(error.localizedDescription)", timeInterval: 3)
        }
    }
}

extension CloudStorageInClassViewController: UploadUtilityDelegate {
    func uploadUtilityDidCompletePick(type: UploadType, url: URL) {
        update(isUploading: true)
        switch type {
        case .image:
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
        case .video:
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
        case .audio:
            // It from file
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: true)
        case .doc:
            // It from file
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: true)
        }
    }
    
    func uploadUtilityDidStartVideoConverting() {
        update(isUploading: true)
    }
    
    func uploadUtilityDidFinishVideoConverting(error: Error?) {
        if let error = error {
            update(isUploading: false)
            toast(error.localizedDescription)
        }
    }
    
    func uploadUtilityDidMeet(error: Error) {
        toast(error.localizedDescription)
    }
}

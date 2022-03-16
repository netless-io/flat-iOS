//
//  HomeCloudStorageViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/3/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import QuickLook
import AVKit
import SafariServices
import Kingfisher

class CloudStorageViewController: CloudStorageDisplayViewController {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
    
    deinit {
        cleanPreviewResource()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Cloud Storage", comment: "")
        navigationItem.rightBarButtonItem = .init(image: UIImage(named: "storage_add"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(onClickAdd))
    }
    
    // MARK: - TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
                super.tableView(tableView, cellForRowAt: indexPath) as? CloudStorageTableViewCell
        else { fatalError() }
        
        let item = container.items[indexPath.row]
        let isPreviewing = item.fileUUID == previewingUUID
        cell.contentView.backgroundColor = isPreviewing ? .cellSelectedBG : .whiteBG
        return cell
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
    
    // MARK: - Actions
    @objc func onClickAdd() {
        let vc = UploadHomeViewController()
        mainContainer?.push(vc)
    }
    
    func share(_ item: StorageFileModel) {
        guard let index = container.items.firstIndex(of: item) else { return }
        let cell = tableView.cellForRow(at: .init(row: index, section: 0))
        let vc = UIActivityViewController(activityItems: [item.fileURL], applicationActivities: nil)
        mainContainer?.concreteViewController.popoverViewController(viewController: vc, fromSource: cell)
    }
    
    // MARK: - Preview
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
}

extension CloudStorageViewController: QLPreviewControllerDelegate {
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

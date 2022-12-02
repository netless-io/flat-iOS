//
//  CustomPreviewViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/23.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import QuickLook
import Kingfisher

class CustomPreviewViewController: QLPreviewController {
    enum Source: Equatable {
        case image(url: URL, fileExtension: String, fileName: String)
        case file(path: String, fileExtension: String, fileName: String)
    }
    
    var clickBackHandler: (()->Void)?
    fileprivate var source: Source?
    fileprivate var currentPreview: AnyPreview? {
        didSet {
            emptyView.isHidden = currentPreview != nil
        }
    }
    
    func update(source: Source) {
        guard source != self.source else { return }
        self.source = source
        loadingDatasource()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let backItem = UIBarButtonItem.init(title: localizeStrings("Close"), style: .plain, target: self, action: #selector(self.onBack))
        self.navigationItem.setLeftBarButton(backItem, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmptyView()
        dataSource = self
        delegate = self
    }
    
    func setupEmptyView() {
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func targetCopyURL(forUUID uuid: String, fileExtension: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(uuid).\(fileExtension)")
    }
    
    // MARK: - Private
    func loadingDatasource() {
        guard let loadingSource = source else { return }
        showActivityIndicator()
        switch loadingSource {
        case .file:
            // TBD:
            // Not file yet
            return
        case .image(url: let url, fileExtension: let fileExtension, fileName: let fileName):
            KingfisherManager.shared.retrieveImageDiskCachePath(fromURL: url) { [weak self] result in
                guard let self = self else { return }
                if self.source != loadingSource {
                    return
                }
                DispatchQueue.main.async {
                    self.stopActivityIndicator()
                }
                switch result {
                case .success(let path):
                    self.copyToPreview(fromPath: path,
                                       toPath: self.targetCopyURL(forUUID: URL(fileURLWithPath: path).lastPathComponent, fileExtension: fileExtension).path,
                                       name: fileName)
                case .failure(let error):
                    self.toast(error.localizedDescription)
                }
            }
        }
    }
    
    func copyToPreview(fromPath: String, toPath: String, name: String) {
        DispatchQueue.global().async {
            do {
                if !FileManager.default.fileExists(atPath: toPath) {
                    try FileManager.default.copyItem(atPath: fromPath, toPath: toPath)
                }
                let previewItem = AnyPreview(previewItemURL: URL(fileURLWithPath: toPath), title: name)
                DispatchQueue.main.async {
                    self.currentPreview = previewItem
                    self.reloadData()
                }
            }
            catch {
                logger.error("previewLocalFileUrlPath, \(error)")
                DispatchQueue.main.async {
                    self.toast(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Action
    @objc func onBack() {
        mainContainer?.removeTop()
        clickBackHandler?()
    }
    
    // MARK: - Lazy
    lazy var emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = .color(type: .background)
        return view
    }()
}

extension CustomPreviewViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        currentPreview == nil ? 0 : 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        currentPreview!
    }
}

extension CustomPreviewViewController: QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        .disabled
    }
}

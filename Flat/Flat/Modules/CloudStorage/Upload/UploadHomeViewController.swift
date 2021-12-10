//
//  UploadHomeViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
#if canImport(PhotosUI)
import PhotosUI
#endif

class UploadHomeViewController: UIViewController {
    var exportingTask: AVAssetExportSession?
    
    enum UploadType: String, CaseIterable {
        case image
        case video
        case music
        case doc
        
        var title: String {
            let str = rawValue.first!.uppercased() + rawValue.dropFirst()
            return NSLocalizedString("Upload " + str, comment: "")
        }
        
        var imageName: String { "upload_" + rawValue }
        
        var bgColor: UIColor {
            switch self {
            case .image:
                return .init(hexString: "#00A0FF")
            case .video:
                return .init(hexString: "#6B6ECF")
            case .music:
                return .init(hexString: "#56C794")
            case .doc:
                return .init(hexString: "#3A69E5")
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Upload", comment: "")
        setupViews()
    }
    
    // MARK: - Action
    @objc func onClick(_ button: UIButton) {
        let type = UploadType.allCases[button.tag]
        let vc: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            switch type {
            case .image:
                var config = PHPickerConfiguration()
                config.filter = .images
                let vc = PHPickerViewController.init(configuration: config)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
                return
            case .video:
                var config = PHPickerConfiguration()
                config.filter = .videos
                let vc = PHPickerViewController.init(configuration: config)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
                return
            case .music:
                let types = ["mp3", "aac"].compactMap { UTType(filenameExtension: $0) }
                vc = UIDocumentPickerViewController.init(forOpeningContentTypes: types)
                vc.delegate = self
                splitViewController?.present(vc, animated: true, completion: nil)
            case .doc:
                let types = ["pdf", "doc", "docx", "ppt", "pptx"].compactMap { UTType(filenameExtension: $0) }
                vc = UIDocumentPickerViewController.init(forOpeningContentTypes: types)
                vc.delegate = self
                splitViewController?.present(vc, animated: true, completion: nil)
            }
        } else {
            // Fallback on earlier versions
            return
        }
    }
    
    @objc func onClickUploadList() {
        mainSplitViewController?.present(tasksViewController, animated: true, completion: nil)
    }
    
    func uploadFile(url: URL, shouldAccessingSecurityScopedResource: Bool) {
        do {
            var result = try UploadService.shared.createUploadTaskFrom(fileURL: url, shouldAccessingSecurityScopedResource: shouldAccessingSecurityScopedResource)
            let newTask = result.task.do(onSuccess: { fillUUID in
                if ConvertConfig.shouldConvertPathExtensions.contains(url.pathExtension.lowercased()) {
                    ApiProvider.shared.request(fromApi: StartConvertRequest(fileUUID: fillUUID)) { result in
                        switch result {
                        case .success:
                            print("submit convert task success")
                            NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil)
                        case .failure:
                            print("submit convert task fail")
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil)
                }
            })
            result = (newTask, result.tracker)
            tasksViewController.appendTask(task: result.task, fileURL: url, subject: result.tracker)
            mainSplitViewController?.present(tasksViewController, animated: true, completion: nil)
        }
        catch {
            print(error)
            toast("error create task \(error.localizedDescription)", timeInterval: 3)
        }
    }
    
    // MARK: - Private
    func setupViews() {
        navigationItem.leftBarButtonItem = .init(title: NSLocalizedString("Uploading List", comment: ""), style: .plain, target: self, action: #selector(onClickUploadList))
        view.backgroundColor = .whiteBG
        let buttons = UploadType.allCases
            .enumerated()
            .map { createButton(title: $0.element.title,
                                imageName: $0.element.imageName,
                                bgColor: $0.element.bgColor,
                                tag: $0.offset) }
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.width.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.width)
        }
        stack.arrangedSubviews.first?.snp.makeConstraints { make in
            make.width.equalTo(114)
        }
    }
    
    func createButton(title: String,
                      imageName: String,
                      bgColor: UIColor,
                      tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        let img = UIImage(named: imageName)?
            .tintColor(.white,
                       backgroundColor: bgColor,
                       cornerRadius: 12,
                       backgroundEdgeInset: .zero)
        button.setImage(img, for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.text, for: .normal)
        button.verticalCenterImageAndTitleWith(8)
        button.tag = tag
        button.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
        return button
    }
    
    // MARK: - Lazy
    var tasksViewController: UploadTasksViewController = {
        let vc = UploadTasksViewController()
        vc.modalPresentationStyle = .pageSheet
        return vc
    }()
}

extension UploadHomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: false, completion: nil)
        guard let url = info[.imageURL] as? URL else { return }
        uploadFile(url: url, shouldAccessingSecurityScopedResource: false)
    }
}

extension UploadHomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        // TODO: covert
        uploadFile(url: url, shouldAccessingSecurityScopedResource: true)
    }
}

@available(iOS 14, *)
extension UploadHomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let item = results.first else { return }
        guard let typeIdentifier = item.itemProvider.registeredTypeIdentifiers.first else { return }
        dismiss(animated: false, completion: nil)
        
        if picker.configuration.filter == .images {
            item.itemProvider.loadObject(ofClass: UIImage.self) { data, error in
                DispatchQueue.main.async {
                    guard let image = data as? UIImage else {
                        self.toast("load image fail")
                        return
                    }
                    if let error = error {
                        self.toast(error.localizedDescription)
                    }
                    guard let jpegData = image.jpegData(compressionQuality: 1) else {
                        self.toast("compress image fail")
                        return
                    }
                    
                    var path = FileManager.default.temporaryDirectory
                    let fileName = (item.itemProvider.suggestedName ?? UUID().uuidString) + ".jpeg"
                    path.appendPathComponent(fileName)
                    let createSuccess = FileManager.default.createFile(atPath: path.path, contents: jpegData, attributes: nil)
                    guard createSuccess else {
                        self.toast("create temp image file error")
                        return
                    }
                    self.uploadFile(url: path, shouldAccessingSecurityScopedResource: false)
                }
            }
            return
        }
        
        item.itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
            guard let self = self else { return }
            guard let url = url else {
                DispatchQueue.main.async {
                    self.toast("load url fail")
                }
                return
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.toast(error.localizedDescription)
                }
                return
            }
            
            // Upload video
            do {
                var cp = FileManager.default.temporaryDirectory
                cp.appendPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: cp.path) {
                    try FileManager.default.removeItem(at: cp)
                }
                try FileManager.default.copyItem(at: url, to: cp)
                DispatchQueue.main.async {
                    self.showActivityIndicator(text: NSLocalizedString("Video Converting", comment: ""))
                }
                
                let ext =  url.pathExtension
                let fileName: String
                if let name = item.itemProvider.suggestedName {
                    fileName = name + ".\(ext)"
                } else {
                    fileName = url.lastPathComponent
                }
                let task = VideoConvertService.convert(url: cp, convertedFileName: fileName) { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.stopActivityIndicator()
                    }
                    do {
                        try FileManager.default.removeItem(at: cp)
                    }
                    catch {
                        print("clean temp video file error \(error)")
                    }
                    switch result {
                    case .success(let url):
                        self.uploadFile(url: url, shouldAccessingSecurityScopedResource: false)
                    case .failure(let error):
                        self.toast(error.localizedDescription)
                    }
                }
                self.exportingTask = task
            }
            catch {
                DispatchQueue.main.async {
                    self.toast(error.localizedDescription)
                }
            }
        }
    }
}

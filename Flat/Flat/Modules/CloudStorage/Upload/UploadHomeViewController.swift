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
    let itemHeight: CGFloat = 114
    var exportingTask: AVAssetExportSession?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Upload", comment: "")
        setupViews()
    }
    
    // MARK: - Action
    @objc func onClick(_ button: UIButton) {
        let type = UploadType.allCases[button.tag]
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
            case .audio, .doc:
                let vc = UIDocumentPickerViewController(forOpeningContentTypes: type.utTypes)
                vc.delegate = self
                mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            }
        } else {
            switch type {
            case .image, .video:
                let vc = UIImagePickerController()
                vc.mediaTypes = type.allowedUTStrings
                vc.videoExportPreset = AVAssetExportPresetPassthrough
                vc.delegate = self
                mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            case .audio, .doc:
                let vc = UIDocumentPickerViewController(documentTypes: type.allowedUTStrings, in: .open)
                vc.delegate = self
                mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @objc func onClickUploadList() {
        mainContainer?.concreteViewController.present(tasksViewController, animated: true, completion: nil)
    }
    
    func uploadFile(url: URL, region: Region, shouldAccessingSecurityScopedResource: Bool) {
        do {
            var result = try UploadService.shared
                .createUploadTaskFrom(fileURL: url,               
                                      region: region,
                                      shouldAccessingSecurityScopedResource: shouldAccessingSecurityScopedResource)
            let newTask = result.task.do(onSuccess: { fillUUID in
                if ConvertService.isFileConvertible(withFileURL: url) {
                    ConvertService.startConvert(fileUUID: fillUUID) { [weak self] result in
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
            })
            result = (newTask, result.tracker)
            tasksViewController.appendTask(task: result.task, fileURL: url, subject: result.tracker)
            mainContainer?.concreteViewController.present(tasksViewController, animated: true, completion: nil)
        }
        catch {
            print(error)
            toast("error create task \(error.localizedDescription)", timeInterval: 3)
        }
    }
    
    // MARK: - Private
    func setupViews() {
        navigationItem.rightBarButtonItem = .init(title: NSLocalizedString("Uploading List", comment: ""),
                                                  style: .plain, target: self,
                                                  action: #selector(onClickUploadList))
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
            make.width.equalTo(itemHeight)
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

// MARK: - Image
extension UploadHomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[.imageURL] as? URL {
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
        } else if let url = info[.mediaURL] as? URL {
            let fileName = UUID().uuidString
            DispatchQueue.main.async {
                self.showActivityIndicator(text: NSLocalizedString("Video Converting", comment: ""))
            }
            let task = VideoConvertService.convert(url: url, convertedFileName: fileName) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.stopActivityIndicator()
                }
                do {
                    try FileManager.default.removeItem(at: url)
                }
                catch {
                    print("clean temp video file error \(error)")
                }
                switch result {
                case .failure(let error):
                    self.toast(error.localizedDescription)
                case .success(let convertedUrl):
                    self.uploadFile(url: convertedUrl, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
                }
            }
            self.exportingTask = task
        }
    }
}

// MARK: - Document
extension UploadHomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: true)
    }
}

// MARK: - PHPicker
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
                    self.uploadFile(url: path, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
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
                        self.uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
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

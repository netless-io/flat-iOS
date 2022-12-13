//
//  UploadUtility.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/15.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers
#if canImport(PhotosUI)
    import PhotosUI
#endif

protocol UploadUtilityDelegate: AnyObject {
    func uploadUtilityDidCompletePick(type: UploadType, url: URL)
    func uploadUtilityDidStartVideoConverting()
    func uploadUtilityDidFinishVideoConverting(error: Error?)
    func uploadUtilityDidMeet(error: Error)
}

enum PresentStyle {
    case main
    case popOver(parent: UIViewController, source: UIView)
}

class UploadUtility: NSObject {
    static let shared = UploadUtility()
    override private init() {}

    fileprivate var exportingTask: AVAssetExportSession?
    fileprivate var uploadType: UploadType?
    fileprivate weak var delegate: UploadUtilityDelegate?

    func start(uploadType type: UploadType, fromViewController: UIViewController, delegate: UploadUtilityDelegate, presentStyle: PresentStyle) {
        uploadType = type
        self.delegate = delegate

        func presentPicker(_ picker: UIViewController) {
            switch presentStyle {
            case .main:
                fromViewController.mainContainer?.concreteViewController.present(picker, animated: true, completion: nil)
            case let .popOver(parent, source):
                parent.popoverViewController(viewController: picker, fromSource: source)
            }
        }

        func present() {
            if #available(iOS 14.0, *) {
                switch type {
                case .image:
                    var config = PHPickerConfiguration()
                    config.filter = .images
                    let vc = PHPickerViewController(configuration: config)
                    vc.delegate = self
                    presentPicker(vc)
                    return
                case .video:
                    var config = PHPickerConfiguration()
                    config.filter = .videos
                    let vc = PHPickerViewController(configuration: config)
                    vc.delegate = self
                    presentPicker(vc)
                    return
                case .audio, .doc:
                    let vc = UIDocumentPickerViewController(forOpeningContentTypes: type.utTypes)
                    vc.delegate = self
                    presentPicker(vc)
                    return
                }
            } else {
                switch type {
                case .image, .video:
                    let vc = UIImagePickerController()
                    vc.mediaTypes = type.allowedUTStrings
                    vc.videoExportPreset = AVAssetExportPresetPassthrough
                    vc.delegate = self
                    presentPicker(vc)
                case .audio, .doc:
                    let vc = UIDocumentPickerViewController(documentTypes: type.allowedUTStrings, in: .open)
                    vc.delegate = self
                    presentPicker(vc)
                }
            }
        }

        func presentImage() {
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { [weak self] s in
                    DispatchQueue.main.async {
                        if s == .denied {
                            self?.delegate?.uploadUtilityDidMeet(error: "permission denied")
                            return
                        }
                        present()
                    }
                }
                return
            case .denied:
                self.delegate?.uploadUtilityDidMeet(error: "permission denied")
            default:
                present()
            }
        }

        switch type {
        case .image, .video:
            presentImage()
        case .audio, .doc:
            present()
        }
    }
}

// MARK: - Image

extension UploadUtility: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[.imageURL] as? URL {
            delegate?.uploadUtilityDidCompletePick(type: .image, url: url)
        } else if let url = info[.mediaURL] as? URL {
            let fileName = UUID().uuidString
            delegate?.uploadUtilityDidStartVideoConverting()
            let task = VideoConvertService.convert(url: url, convertedFileName: fileName) { [weak self] result in
                guard let self = self else { return }
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    logger.error("clean temp video file error, \(error)")
                }
                switch result {
                case let .failure(error):
                    DispatchQueue.main.async {
                        self.delegate?.uploadUtilityDidFinishVideoConverting(error: error)
                    }
                case let .success(convertedUrl):
                    DispatchQueue.main.async {
                        self.delegate?.uploadUtilityDidCompletePick(type: .video, url: convertedUrl)
                    }
                }
            }
            exportingTask = task
        }
    }
}

// MARK: - Document

extension UploadUtility: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        guard let type = uploadType else { return }
        delegate?.uploadUtilityDidCompletePick(type: type, url: url)
    }
}

// MARK: - PHPicker

@available(iOS 14, *)
extension UploadUtility: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let item = results.first else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        guard let typeIdentifier = item.itemProvider.registeredTypeIdentifiers.first else { return }
        picker.dismiss(animated: true, completion: nil)

        if picker.configuration.filter == .images {
            item.itemProvider.loadObject(ofClass: UIImage.self) { data, error in
                DispatchQueue.main.async {
                    guard let image = data as? UIImage else {
                        self.delegate?.uploadUtilityDidMeet(error: "load image fail")
                        return
                    }
                    if let error = error {
                        self.delegate?.uploadUtilityDidMeet(error: error)
                        return
                    }
                    guard let jpegData = image.jpegData(compressionQuality: 1) else {
                        self.delegate?.uploadUtilityDidMeet(error: "compress image fail")
                        return
                    }

                    var path = FileManager.default.temporaryDirectory
                    let fileName = (item.itemProvider.suggestedName ?? UUID().uuidString) + ".jpeg"
                    path.appendPathComponent(fileName)
                    let createSuccess = FileManager.default.createFile(atPath: path.path, contents: jpegData, attributes: nil)
                    guard createSuccess else {
                        self.delegate?.uploadUtilityDidMeet(error: "create temp image file error")
                        return
                    }
                    self.delegate?.uploadUtilityDidCompletePick(type: .image, url: path)
                }
            }
            return
        } else {
            item.itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
                guard let self = self else { return }
                guard let url = url else {
                    DispatchQueue.main.async {
                        self.delegate?.uploadUtilityDidMeet(error: "load url fail")
                    }
                    return
                }
                if let error = error {
                    DispatchQueue.main.async {
                        self.delegate?.uploadUtilityDidMeet(error: error.localizedDescription)
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
                        self.delegate?.uploadUtilityDidStartVideoConverting()
                    }

                    let ext = url.pathExtension
                    let fileName: String
                    if let name = item.itemProvider.suggestedName {
                        fileName = name + ".\(ext)"
                    } else {
                        fileName = url.lastPathComponent
                    }
                    let task = VideoConvertService.convert(url: cp, convertedFileName: fileName) { [weak self] result in
                        guard let self = self else { return }
                        do {
                            try FileManager.default.removeItem(at: cp)
                        } catch {
                            logger.error("clean temp video file error, \(error)")
                        }

                        DispatchQueue.main.async {
                            switch result {
                            case let .success(url):
                                self.delegate?.uploadUtilityDidFinishVideoConverting(error: nil)
                                self.delegate?.uploadUtilityDidCompletePick(type: .video, url: url)
                            case let .failure(error):
                                self.delegate?.uploadUtilityDidMeet(error: error)
                            }
                        }
                    }
                    self.exportingTask = task
                } catch {
                    DispatchQueue.main.async {
                        self.delegate?.uploadUtilityDidMeet(error: error)
                    }
                }
            }
        }
    }
}

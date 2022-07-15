//
//  UploadHomeViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class UploadHomeViewController: UIViewController {
    let itemHeight: CGFloat = 114
    
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
        UploadUtility.shared.start(uploadType: type,
                                   fromViewController: self,
                                   delegate: self,
                                   presentStyle: .main)
    }
    
    func presentTask() {
        mainContainer?.concreteViewController.present(tasksViewController, animated: true, completion: nil)
    }
    
    @objc func onClickUploadList() {
        presentTask()
    }
    
    func uploadFile(url: URL, region: Region, shouldAccessingSecurityScopedResource: Bool) {
        do {
            var result = try UploadService.shared
                .createUploadTaskFrom(fileURL: url,               
                                      region: region,
                                      shouldAccessingSecurityScopedResource: shouldAccessingSecurityScopedResource)
            let newTask = result.task.do(onSuccess: { fillUUID in
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
            })
            result = (newTask, result.tracker)
            tasksViewController.appendTask(task: result.task, fileURL: url, subject: result.tracker)
            presentTask()
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
        button.titleLabel?.minimumScaleFactor = 0.5
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setTitleColor(.text, for: .normal)
        button.verticalCenterImageAndTitleWith(8)
        button.tag = tag
        button.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
        return button
    }
    
    // MARK: - Lazy
    lazy var tasksViewController: UploadTasksViewController = {
        let vc = UploadTasksViewController()
        vc.modalPresentationStyle = .pageSheet
        return vc
    }()
}


extension UploadHomeViewController: UploadUtilityDelegate {
    func uploadUtilityDidCompletePick(type: UploadType, url: URL) {
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
        showActivityIndicator()
    }
    
    func uploadUtilityDidFinishVideoConverting(error: Error?) {
        stopActivityIndicator()
        if let error = error {
            toast(error.localizedDescription)
        }
    }
    
    func uploadUtilityDidMeet(error: Error) {
        toast(error.localizedDescription)
    }
}

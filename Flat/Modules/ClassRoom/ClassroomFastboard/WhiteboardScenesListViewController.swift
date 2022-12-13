//
//  WhiteboardScenesListViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Kingfisher
import UIKit
import Whiteboard

struct RoomPreviewImage: ImageDataProvider {
    let room: WhiteRoom
    var cacheKey: String

    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        room.getSceneSnapshotImage(cacheKey) { sceneImage in
            if let jpgData = sceneImage?.jpegData(compressionQuality: 1) {
                handler(.success(jpgData))
            } else {
                handler(.failure("get image fail"))
            }
        }
    }
}

class WhiteboardScenesListViewController: UIViewController {
    let room: WhiteRoom
    var scenes: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    init(room: WhiteRoom) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .color(type: .background)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        room.getEntireScenes { [weak self] scenes in
            let newScenes = scenes.reduce(into: [String]()) { partialResult, kv in
                let part = kv.value.map {
                    kv.key + $0.name
                }
                partialResult.append(contentsOf: part)
            }
            newScenes.forEach { KingfisherManager.shared.cache.removeImage(forKey: $0) }
            self?.scenes = newScenes
        }
    }

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.register(ScenePreviewCell.self, forCellReuseIdentifier: "ScenePreviewCell")
        return view
    }()
}

extension WhiteboardScenesListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        scenes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScenePreviewCell") as! ScenePreviewCell
        cell.selectionStyle = .none
        let scene = scenes[indexPath.row]
        let source = RoomPreviewImage(room: room, cacheKey: scene)
        cell.showActivityIndicator()
        cell.previewImageView.kf.setImage(with: source) { [weak cell] _ in
            cell?.stopActivityIndicator()
        }
        return cell
    }

    @objc func save(image _: UIImage, didFinishSavingWithError: NSError?, contextInfo _: AnyObject) {
        if let error = didFinishSavingWithError {
            toast(error.localizedDescription)
        } else {
            toast(localizeStrings("SaveSuccess"))
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let scene = scenes[indexPath.row]
        guard let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: scene) else {
            toast(localizeStrings("Loading"))
            return
        }
        let alertController = UIAlertController(title: localizeStrings("SaveToAlbum"), message: "", preferredStyle: .alert)
        alertController.addAction(.init(title: localizeStrings("Cancel"), style: .cancel, handler: nil))
        let imageAction = UIAlertAction(title: "", style: .default, handler: nil)
        let width = CGFloat(270)
        let height = width * 9.0 / 16.0
        let resizeImage = image.kf.resize(to: .init(width: width, height: height))
        let imageView = UIImageView(frame: .init(origin: .init(x: 0, y: 64), size: .init(width: width, height: height + 10)))
        imageView.tintColor = .red
        imageView.image = resizeImage
        imageAction.setValue(resizeImage, forKey: "image")
        alertController.view.addSubview(imageView)
        imageAction.isEnabled = false
        alertController.addAction(imageAction)
        alertController.addAction(.init(title: localizeStrings("Confirm"), style: .default, handler: { _ in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.save(image:didFinishSavingWithError:contextInfo:)), nil)
        }))
        present(alertController, animated: false, completion: nil)
    }
}

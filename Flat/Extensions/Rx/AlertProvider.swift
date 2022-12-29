//
//  AlertProvider.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/18.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

struct AlertModel {
    struct ActionModel {
        var title: String
        var style: UIAlertAction.Style
        var handler: ((UIAlertAction) -> Void)?

        static let empty = ActionModel(title: "", style: .default, handler: nil)
        static let cancel = ActionModel(title: localizeStrings("Cancel"), style: .cancel, handler: nil)
        static let confirm = ActionModel(title: localizeStrings("Confirm"), style: .default, handler: nil)
    }

    var title: String?
    var message: String?
    var preferredStyle: UIAlertController.Style
    var actionModels: [ActionModel]
}

enum AlertBuilder {
    static func buildAlertController(for model: AlertModel) -> UIAlertController {
        let controller = UIAlertController(title: model.title,
                                           message: model.message,
                                           preferredStyle: model.preferredStyle)
        model.actionModels.forEach {
            controller.addAction(UIAlertAction(title: $0.title,
                                               style: $0.style,
                                               handler: $0.handler))
        }
        return controller
    }
}

protocol AlertProvider {
    func showAlert(with model: AlertModel) -> Single<AlertModel.ActionModel>
    func showActionSheet(with model: AlertModel, source: TapSource?) -> Single<AlertModel.ActionModel>
    /// When show the alert with same tag before last one return. It just return a nil signal
    func showAlert(with model: AlertModel, tag: String) -> Single<AlertModel.ActionModel?>
    func showActionSheet(with model: AlertModel, tag: String, source: TapSource?) -> Single<AlertModel.ActionModel?>
}

class DefaultAlertProvider: AlertProvider {
    weak var root: UIViewController?

    var customPopOverSourceProvider: ((AlertModel) -> (UIView, (dx: CGFloat, dy: CGFloat)))?
    var presentingTagAlerts: Set<String> = .init()

    func showActionSheet(with model: AlertModel, tag: String, source: TapSource?) -> Single<AlertModel.ActionModel?> {
        if presentingTagAlerts.contains(tag) {
            logger.info("present showActionSheet \(model) was presenting")
            return .just(nil)
        }
        presentingTagAlerts.insert(tag)
        let newActionModels = model.actionModels.map { m -> AlertModel.ActionModel in
            .init(title: m.title, style: m.style) { [weak self] action in
                m.handler?(action)
                self?.presentingTagAlerts.remove(tag)
            }
        }
        var replacedModel = model
        replacedModel.actionModels = newActionModels
        return showActionSheet(with: replacedModel, source: source).map { $0 as AlertModel.ActionModel? }
    }

    func showAlert(with model: AlertModel, tag: String) -> Single<AlertModel.ActionModel?> {
        if presentingTagAlerts.contains(tag) {
            logger.info("present showAlert \(model) was presenting")
            return .just(nil)
        }
        presentingTagAlerts.insert(tag)
        let newActionModels = model.actionModels.map { m -> AlertModel.ActionModel in
            .init(title: m.title, style: m.style) { [weak self] action in
                m.handler?(action)
                self?.presentingTagAlerts.remove(tag)
            }
        }
        var replacedModel = model
        replacedModel.actionModels = newActionModels
        return showAlert(with: replacedModel).map { $0 as AlertModel.ActionModel? }
    }

    // Cancel style will be called when white space clicked
    func showActionSheet(with alertModel: AlertModel, source: TapSource?) -> Single<AlertModel.ActionModel> {
        guard let root else { return .error("root deinit") }
        let task = Single<AlertModel.ActionModel>.create { observer in
            let models = alertModel.actionModels.map { model -> AlertModel.ActionModel in
                var newModel = model
                newModel.handler = { action in
                    model.handler?(action)
                    observer(.success(model))
                }
                return newModel
            }
            var newModel = alertModel
            newModel.actionModels = models
            let vc = AlertBuilder.buildAlertController(for: newModel)

            if let customPopOverSourceProvider = self.customPopOverSourceProvider {
                let p = customPopOverSourceProvider(alertModel)
                root.popoverViewController(viewController: vc,
                                           fromSource: p.0,
                                           sourceBoundsInset: p.1)
            } else {
                if let source = source as? UIView {
                    root.popoverViewController(viewController: vc, fromSource: source)
                } else {
                    root.popoverViewController(viewController: vc, fromSource: root.view)
                }
            }
            return Disposables.create()
        }

        return root.rx.isPresenting
            .asObservable()
            .asSingle()
            .flatMap { [weak root] presenting -> Single<AlertModel.ActionModel> in
                guard let root else { return .just(.empty) }
                if !presenting { return task }
                return root.rx.dismiss(animated: true).flatMap { task }
            }
    }

    func showAlert(with alertModel: AlertModel) -> Single<AlertModel.ActionModel> {
        guard let root else { return .error("root deinit") }
        return .create { observer in
            let models = alertModel.actionModels.map { model -> AlertModel.ActionModel in
                var newModel = model
                newModel.handler = { action in
                    model.handler?(action)
                    observer(.success(model))
                }
                return newModel
            }
            var newModel = alertModel
            newModel.actionModels = models
            let vc = AlertBuilder.buildAlertController(for: newModel)
            modalTopViewControllerFrom(root: root).present(vc, animated: true, completion: nil)
            return Disposables.create()
        }
    }
}

protocol TapSource {}
extension UIButton: TapSource {}

extension Reactive where Base: UIButton {
    var sourceTap: ControlEvent<TapSource> {
        ControlEvent(events: controlEvent(.touchUpInside).map { self.base as TapSource })
    }
}

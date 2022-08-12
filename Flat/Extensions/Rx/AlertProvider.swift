//
//  AlertProvider.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/18.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

struct AlertModel {
    struct ActionModel {
        var title: String
        var style: UIAlertAction.Style
        var handler: ((UIAlertAction)->Void)?
        
        static let empty = ActionModel(title: "", style: .default, handler: nil)
        static let cancel = ActionModel(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        static let confirm = ActionModel(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: nil)
    }
    
    var title: String?
    var message: String?
    var preferredStyle: UIAlertController.Style
    var actionModels: [ActionModel]
}

struct AlertBuilder {
    static func buildAlertController(for model: AlertModel) -> UIAlertController {
           let controller = UIAlertController(title: model.title,
                                              message: model.message,
                                              preferredStyle: model.preferredStyle)
           model.actionModels.forEach({
               controller.addAction(UIAlertAction(title: $0.title,
                                                  style: $0.style,
                                                  handler: $0.handler)) })
           return controller
    }
}

protocol AlertProvider {
    func showAlert(with model: AlertModel) -> Single<AlertModel.ActionModel>
    
    func showActionSheet(with model: AlertModel, source: TapSource?) -> Single<AlertModel.ActionModel>
}

class DefaultAlertProvider: AlertProvider {
    weak var root: UIViewController?
    
    var customPopOverSourceProvider: ((AlertModel) -> (UIView, CGRect))?
    
    // Cancel style will be called when white space clicked
    func showActionSheet(with model: AlertModel, source: TapSource?) -> Single<AlertModel.ActionModel> {
        guard let root = root else {
            return .error("root deinit")
        }
        let task = Single<AlertModel.ActionModel>.create { observer in
            let models = model.actionModels.map { model -> AlertModel.ActionModel in
                var newModel = model
                newModel.handler = { action in
                    model.handler?(action)
                    observer(.success(model))
                }
                return newModel
            }
            var newModel = model
            newModel.actionModels = models
            let vc = AlertBuilder.buildAlertController(for: newModel)
            vc.modalPresentationStyle = .popover
            if let customPopOverSourceProvider = self.customPopOverSourceProvider {
                let i = customPopOverSourceProvider(model)
                vc.popoverPresentationController?.sourceView = i.0
                vc.popoverPresentationController?.sourceRect = i.1
            } else {
                if let source = source as? UIView {
                    vc.popoverPresentationController?.sourceView = source
                    vc.popoverPresentationController?.sourceRect = source.bounds
                } else {
                    vc.popoverPresentationController?.sourceView = root.view
                    vc.popoverPresentationController?.sourceRect = .zero
                }
            }
            root.present(vc, animated: true, completion: nil)
            return Disposables.create()
        }
        
        return root.rx.isPresenting
            .asObservable()
            .asSingle()
            .flatMap { [weak root] presenting -> Single<AlertModel.ActionModel> in
                guard let root = root else { return .just(.empty) }
                if !presenting { return task }
                return root.rx.dismiss(animated: true).flatMap { task }
            }
    }
    
    func showAlert(with model: AlertModel) -> Single<AlertModel.ActionModel> {
        guard let root = root else {
            return .error("root deinit")
        }
        return .create { observer in
            let models = model.actionModels.map { model -> AlertModel.ActionModel in
                var newModel = model
                newModel.handler = { action in
                    model.handler?(action)
                    observer(.success(model))
                }
                return newModel
            }
            var newModel = model
            newModel.actionModels = models
            let vc = AlertBuilder.buildAlertController(for: newModel)
            root.present(vc, animated: true, completion: nil)
            return Disposables.create()
        }
    }
}

protocol TapSource {}
extension UIButton: TapSource {}

extension Reactive where Base: UIButton {
    var sourceTap: ControlEvent<TapSource> {
        return ControlEvent(events: controlEvent(.touchUpInside).map { self.base as TapSource })
    }
}

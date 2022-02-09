//
//  UIViewController+Alert.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import UIKit

extension UIViewController {
    @discardableResult
    func showCheckAlert(title: String = NSLocalizedString("Alert", comment: ""),
                        message: String = "",
                        completionHandler: (()->Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(.init(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: { _ in
            completionHandler?()
        }))
        present(alertController, animated: true, completion: nil)
        return alertController
    }
    
    @discardableResult
    func showAlertWith(title: String = NSLocalizedString("Alert", comment: ""),
                       message: String,
                       completionHandler: (()->Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: NSLocalizedString("Confirm", comment: ""), style: .default) { _ in
            completionHandler?()
        })
        present(alertController, animated: true, completion: nil)
        return alertController
    }
}

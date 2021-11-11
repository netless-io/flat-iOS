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
    func showCheckAlert(title: String = "提示",
                        message: String = "",
                        completionHandler: (()->Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: "取消", style: .cancel, handler: nil))
        alertController.addAction(.init(title: "确认", style: .default, handler: { _ in
            completionHandler?()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWith(title: String = "提示",
                       message: String,
                       completionHandler: (()->Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: "确认", style: .default) { _ in
            completionHandler?()
        })
        present(alertController, animated: true, completion: nil)
    }
}

//
//  UIViewController+Rx.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/17.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIViewController {
    func dismiss(animated: Bool) -> Single<Void> {
        Single<Void>.create { observer in
            self.base.dismiss(animated: animated) {
                observer(.success(()))
            }
            return Disposables.create()
        }
    }
    
    var isPresenting: Driver<Bool> {
        Single<Bool>.create { ob in
            let vc = self.base
            if vc.presentingViewController != nil {
                ob(.success(true))
            } else {
                ob(.success(false))
            }
            return Disposables.create()
        }.asDriver(onErrorJustReturn: false)
    }
    
    var isPresented: Driver<Bool> {
        Single<Bool>.create { ob in
            let vc = self.base
            if vc.isBeingPresented {
                ob(.success(true))
            } else if vc.presentingViewController != nil {
                ob(.success(true))
            } else {
                ob(.success(false))
            }
            return Disposables.create()
        }.asDriver(onErrorJustReturn: false)
    }
}

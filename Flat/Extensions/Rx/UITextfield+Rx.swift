//
//  UITextfield+Rx.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/23.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UITextField {
    var editing: Driver<Bool> {
        base.rx
            .controlEvent([.editingDidBegin, .editingDidEnd])
            .map { _ in self.base.isEditing }
            .asDriver(onErrorJustReturn: false)
    }
}

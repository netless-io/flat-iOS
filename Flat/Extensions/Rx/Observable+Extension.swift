//
//  Observable+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/18.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension ObservableType {
    func mapToVoid() -> Observable<Void> {
        map { _ in () }
    }

    func asDriverOnErrorJustComplete() -> Driver<Element> {
        asDriver { _ in
            Driver.empty()
        }
    }
}

extension PrimitiveSequenceType where Trait == SingleTrait {
    func mapToVoid() -> Single<Void> {
        map { _ in () }
    }
}

extension PrimitiveSequenceType where Trait == MaybeTrait {
    func mapToVoid() -> Maybe<Void> {
        map { _ in () }
    }
}

extension SharedSequenceConvertibleType {
    func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
        map { _ in () }
    }
}

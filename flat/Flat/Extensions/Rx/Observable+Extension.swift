//
//  Observable+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/18.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension ObservableType {
    func mapToVoid() -> Observable<Void> {
        map { _ -> Void in return () }
    }
    
    func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { error in
            return Driver.empty()
        }
    }
}

extension PrimitiveSequenceType where Trait == SingleTrait {
    func mapToVoid() -> Single<Void> {
        map { _ -> Void in return () }
    }
}

extension PrimitiveSequenceType where Trait == MaybeTrait {
    func mapToVoid() -> Maybe<Void> {
        map { _ -> Void in return () }
    }
}

extension SharedSequenceConvertibleType {
    func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
        map { _ -> Void in return () }
    }
}

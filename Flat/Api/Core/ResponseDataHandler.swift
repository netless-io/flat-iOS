//
//  ResponseHandler.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift

protocol ResponseDataHandler {
    func processResponseData<T: Decodable>(_ data: Data, decoder: JSONDecoder, forResponseType: T.Type) throws -> T
}

extension ResponseDataHandler {
    func processObservableResponseData<T>(_ data: Data, decoder: JSONDecoder, forResponseType _: T.Type) -> Observable<T> where T: Decodable {
        return .create { observer in
            do {
                let result: T = try self.processResponseData(data, decoder: decoder, forResponseType: T.self)
                observer.onNext(result)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}

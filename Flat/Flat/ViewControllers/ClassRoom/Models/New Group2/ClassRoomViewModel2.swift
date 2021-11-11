//
//  ClassRoomViewModel2.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/10.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import RxCocoa
import RxSwift

class ClassRoomViewModel2 {
    
    func input(_ input: ClassRoomRtm2) {
        let msgs: BehaviorSubject<[Message]> = .init(value: [])
        
//        let page: Observable<Int>!
//        let searchTerm: Observable<String>!
//
//        let q = Observable.combineLatest(page, searchTerm)
        
        let history = input.requestHistory().asObservable()
        let newMessages = input.newMessagePublish
            .reduce([Message]()) { result, newItem in
                var new = result
                new.append(newItem)
                return new
            }
        let r = Observable.combineLatest(history, newMessages) { i, j in
            return i + j
        }
        
        
        
        
//        let q = Observable.amb(history, newMessage)
        
//        let result = history.flatMap { msgs in
//            return BehaviorSubject<[Message]>.init(value: msgs)
//        }
        
//        let r = Observable.combineLatest(result, newMessage)
//            .map { i, j -> [Message] in
//                var new = i
//                new.append(j)
//                return new
//            }
        
        
//        Observable.combineLatest(history, newMessage).reduce([Message]()) { result, tuple in
//            var new
//        }
        
        
//        Observable.combineLatest(history, input.newMessagePublish) { i, j in
//
//        }
        
//        let q = Observable.combineLatest(history, input.newMessagePublish)
//            .map { i, j in
//
//            }
//            .map { i, j in
//
//            }
    }
}

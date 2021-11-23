//
//  WhiteboardMenuNavigator.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/23.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Whiteboard

protocol WhiteboardMenuNavigator {
    func presentPicker(item: WhitePannelItem)
    
    func presentColorAndWidthPicker(item: WhitePannelItem, lineWidth: Float)
    
    func getNewApplianceObserver() -> Observable<WhiteApplianceNameKey>
    
    func getColorAndWidthObserver() -> Observable<(UIColor, Float)>
}

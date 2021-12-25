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
    func presentPicker(item: WhitePanelItem)
    
    func presentColorAndWidthPicker(item: WhitePanelItem, lineWidth: Float)
    
    func getNewOperationObserver() -> Observable<WhiteboardPanelOperation>
    
    func getColorAndWidthObserver() -> Observable<(UIColor, Float)>
}

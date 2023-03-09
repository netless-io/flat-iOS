//
//  VideoDraggingCanvasProvider.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/1.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

protocol VideoDraggingCanvasProvider {
    func getDraggingView() -> UIView
    func getDraggingLayoutFor(index: Int, totalCount: Int) -> CGRect
    func onStartGridPreview()
    func onEndGridPreview()
    func startHint()
    func endHint()
}

//
//  WhiteBoardingViewControllerDelegate.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Whiteboard

protocol WhiteboardViewControllerDelegate: AnyObject{
    func whiteboadViewController(_ controller: WhiteboardViewController, error: Error)
    
    func whiteboardViewControllerDidUpdatePhase(_ controller: WhiteboardViewController, phase: WhiteRoomPhase)
}

//
//  PopOverPresentationStyleAdaptor.swift
//  
//
//  Created by xuyunshi on 2021/12/6.
//

import UIKit

typealias PresentationStyleGet = ((UIPresentationController, UITraitCollection) ->UIModalPresentationStyle)

private var anyPopOverDelegateKey: Void?

extension UIViewController {
    var adaptivePresentationStyleAdaptor: PresentationStyleGet? {
        return nil
    }
    
    var anyPopOverDelegate: AnyPopOverDelegate? {
        get {
            objc_getAssociatedObject(self, &anyPopOverDelegateKey) as? AnyPopOverDelegate
        }
        set {
            objc_setAssociatedObject(self, &anyPopOverDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

class AnyPopOverDelegate: NSObject, UIPopoverPresentationControllerDelegate {
    var adaptivePresentationStyleAdaptor: PresentationStyleGet?
    
    init(adaptivePresentationStyleAdaptor: PresentationStyleGet?) {
        self.adaptivePresentationStyleAdaptor = adaptivePresentationStyleAdaptor
        super.init()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if let style = adaptivePresentationStyleAdaptor?(controller, traitCollection) {
            return style
        } else {
            return .none
        }
    }
}

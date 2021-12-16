//
//  SideBarCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/16.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

@available(iOS 14.0, *)
class SideBarCell: UICollectionViewListCell {
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        guard
            var config = self.contentConfiguration as? UIListContentConfiguration
        else {
            return
        }
        config.imageProperties.tintColor = state.isSelected ? .whiteBG : .blackBG
        config.textProperties.color = state.isSelected ? .whiteBG : .text
        self.contentConfiguration = config
        self.backgroundConfiguration?.backgroundColor = state.isSelected ? self.tintColor : .clear
    }
}

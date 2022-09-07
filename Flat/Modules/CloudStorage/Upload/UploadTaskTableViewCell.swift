//
//  UploadTaskTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import RxSwift

class UploadTaskTableViewCell: UITableViewCell {
    var progressObserveDisposeBag: DisposeBag?
    var operationClickHandler: (()->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .color(type: .background)
    }
    
    @IBAction func operationButton(_ sender: Any) {
        operationClickHandler?()
    }
    
    @IBOutlet weak var operationButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
}

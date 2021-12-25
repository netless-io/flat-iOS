//
//  AppliancePickerCollectionViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class AppliancePickerCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func triggerActivityAnimation() {
        let view: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            view = UIActivityIndicatorView(style: .medium)
        } else {
            view = UIActivityIndicatorView(style: .gray)
        }
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        view.startAnimating()
        imageView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            view.stopAnimating()
            self.imageView.isHidden = false
        }
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        return view
    }()
}

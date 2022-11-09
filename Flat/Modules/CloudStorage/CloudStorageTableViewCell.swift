//
//  CloudStorageTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class CloudStorageTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if animated {
            selectionView.layer.backgroundColor = selected ? UIColor.color(type: .primary, .weaker).cgColor : UIColor.color(type: .background).cgColor
        } else {
            selectionView.backgroundColor = selected ?  .color(type: .primary, .weaker) : .color(type: .background)
        }
        moreActionButton.isSelected = selected
    }
    
    func setupViews() {
        backgroundColor = .color(type: .background)
        contentView.backgroundColor = .color(type: .background)
        
        let textStack = UIStackView(arrangedSubviews: [fileNameLabel, sizeAndTimeLabel])
        textStack.axis = .vertical
        textStack.distribution = .fillEqually
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [iconImage, textStack, rightArrowImageView, moreActionButton])
        stackView.spacing = 12
        stackView.axis = .horizontal
        stackView.distribution = .fill
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        iconImage.snp.makeConstraints { $0.width.equalTo(20) }
        rightArrowImageView.snp.makeConstraints { $0.width.equalTo(24) }
        moreActionButton.snp.makeConstraints { $0.width.equalTo(44) }
        
        contentView.addSubview(convertingActivityView)
        convertingActivityView.snp.makeConstraints { make in
            make.centerX.equalTo(iconImage.snp.right).inset(2)
            make.centerY.equalTo(iconImage.snp.bottom).inset(13)
            make.width.height.equalTo(10)
        }
        convertingActivityView.transform = .init(scaleX: 0.5, y: 0.5)
        
        contentView.addLine(direction: .bottom, color: .borderColor, inset: .init(top: 0, left: 52, bottom: 0, right: 16))
        
        moreActionButton.isHidden = true
        rightArrowImageView.isHidden = true
        
        contentView.insertSubview(selectionView, at: 0)
        selectionView.clipsToBounds = true
        selectionView.layer.cornerRadius = 6
        selectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8))
        }
    }
    
    func stopConvertingAnimation() {
        convertingActivityView.isHidden = true
        convertingActivityView.stopAnimating()
    }
    
    func startConvertingAnimation() {
        convertingActivityView.isHidden = false
        convertingActivityView.startAnimating()
    }
    
    func updateActivityAnimate(_ animate: Bool) {
        if animate {
            if activity.superview == nil {
                contentView.addSubview(activity)
                activity.snp.makeConstraints { make in
                    make.edges.equalTo(iconImage)
                }
            }
            activity.isHidden = false
            activity.startAnimating()
        } else {
            activity.stopAnimating()
        }
    }

    lazy var convertingActivityView: UIActivityIndicatorView = {
        let view: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            view = UIActivityIndicatorView(style: .medium)
        } else {
            view = UIActivityIndicatorView(style: .gray)
        }
        view.color = .color(type: .primary)
        return view
    }()
    
    lazy var activity: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()
    
    lazy var iconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var moreActionButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTraitRelatedBlock { btn in
            btn.setImage(UIImage(named: "cloud_file_more")?.tintColor(
                .color(light: .init(hexString: "#1A1E21"), dark: .grey3)
                .resolveDynamicColorPatchiOS13With(btn.traitCollection)
            ), for: .normal)
            btn.setImage(UIImage(named: "cloud_file_more")?.tintColor(
                .color(type: .primary)
                .resolveDynamicColorPatchiOS13With(btn.traitCollection)
            ), for: .selected)
        }
        return btn
    }()
    
    lazy var rightArrowImageView:UIImageView = {
        let view = UIImageView()
        view.setTraitRelatedBlock { v in
            v.image = UIImage(named: "arrowRight")?.tintColor(.color(type: .text).resolveDynamicColorPatchiOS13With(v.traitCollection))
        }
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var sizeAndTimeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .color(type: .text, .weak)
        return label
    }()
    
    lazy var fileNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 16)
        label.textColor = .color(type: .text)
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    lazy var selectionView = UIView()
}

//
//  CancellationViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/19.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import RxSwift

class CancellationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            self.startTimer()
        }
        agreementCheckButton.rx.tap
            .map { [unowned self] in !self.agreementCheckButton.isSelected }
            .asDriverOnErrorJustComplete()
            .drive(agreementCheckButton.rx.isSelected)
            .disposed(by: rx.disposeBag)
        
        confirmButton.rx.tap
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.showCheckAlert(title: NSLocalizedString("CancelationAndLogout", comment: ""), message: "") {
                    weakSelf.showActivityIndicator()
                    ApiProvider.shared.request(fromApi: AccountCancelationRequest()) { result in
                        weakSelf.stopActivityIndicator()
                        switch result {
                        case .failure(let error):
                            weakSelf.toast(error.localizedDescription)
                        case .success:
                            AuthStore.shared.logout()
                        }
                    }
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindEnable() {
        agreementCheckButton.rx.tap
            .map { [unowned self] in !self.confirmButton.isEnabled}
            .asDriver(onErrorJustReturn: true)
            .startWith(agreementCheckButton.isSelected)
            .drive(with: confirmButton, onNext: { btn, enable in
                btn.isEnabled = enable
                btn.layer.borderWidth = enable ? 1 / UIScreen.main.scale : 0
            })
            .disposed(by: rx.disposeBag)
    }
    
    func startTimer() {
        let start = confirmButton.title(for: .normal) ?? ""
        let count = 12
        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(until: { $0 > count })
            .map { count - $0 }
            .map { "\(start)\($0 > 0 ? "(\($0)S)" : "")" }
            .asDriver(onErrorJustReturn: start)
            .do(onCompleted: { [weak self] in
                self?.bindEnable()
            })
            .drive(confirmButton.rx.title(for: .disabled))
            .disposed(by: rx.disposeBag)
    }

    func setupViews() {
        title = NSLocalizedString("AccountCancellation", comment: "")
        
        view.backgroundColor = .color(type: .background)
        
        let tl = UILabel()
        tl.text = NSLocalizedString("AccountCancelationInfoTitle", comment: "")
        tl.textColor = .color(type: .text)
        tl.font = .systemFont(ofSize: 16, weight: .semibold)
        tl.textAlignment = .center
        
        let cl = UILabel()
        cl.text = NSLocalizedString("AccountCancelationInfo", comment: "")
        cl.textColor = .color(type: .text)
        cl.font = .systemFont(ofSize: 14)
        cl.numberOfLines = 0
        let stackView = UIStackView(arrangedSubviews: [tl, cl])
        stackView.axis = .vertical
        
        tl.snp.makeConstraints { $0.height.equalTo(56) }
        
        let bottomHeight: CGFloat = 40
        let margin = CGFloat(16)
        let srcView = UIScrollView()
        view.addSubview(srcView)
        srcView.addSubview(stackView)
        srcView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(bottomHeight + margin)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin))
            make.width.equalTo(view).offset(-(2 * margin))
        }
        
        let bottomStack = UIStackView(arrangedSubviews: [agreementCheckButton, confirmButton])
        bottomStack.backgroundColor = .color(type: .background)
        bottomStack.axis = .horizontal
        bottomStack.distribution = .fill
        agreementCheckButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        confirmButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        confirmButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.addSubview(bottomStack)
        bottomStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(margin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(margin)
            make.height.equalTo(bottomHeight)
        }
    }
    
    lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(NSLocalizedString("CancelationAndLogout", comment: ""), for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.setTitleColor(.color(type: .text), for: .disabled)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        let disableImage = UIImage.imageWith(color: .lightGray)
        button.setBackgroundImage(disableImage, for: .disabled)
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.clipsToBounds = true
        button.layer.cornerRadius = 4
        button.isEnabled = false
        return button
    }()
    
    lazy var agreementCheckButton: UIButton = {
        let btn = UIButton.checkBoxStyleButton()
        btn.setTitleColor(.color(type: .text), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitle("  " + NSLocalizedString("Have read and agree", comment: "") + " ", for: .normal)
        btn.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        return btn
    }()
}

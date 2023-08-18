//
//  AvatarNickNameSettingViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/18.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import Kingfisher

class AvatarNickNameSettingViewController: UIViewController {
    let profileUpdate = ProfileUpdate()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .fullScreen
        }
        preferredContentSize = .init(width: 480, height: 480)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        NotificationCenter.default.addObserver(self, selector: #selector(onAvatarUpdate), name: avatarUpdateNotificationName, object: nil)
    }
    
    func setupViews() {
        view.backgroundColor = .color(type: .background)
        addPresentTitle(localizeStrings("Profile"))
        addPresentCloseButton { [weak self] in
            self?.presentingViewController?.dismiss(animated: true)
        }
        
        view.addSubview(mainContentView)
        mainContentView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(16)
            make.width.equalToSuperview().inset(16).priority(.medium)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(44)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.snp.bottom).inset(16).priority(.medium)
        }
    }

    @objc
    func onFinish() {
        let text = nickNameTextfield.text ?? ""
        if text.isEmptyOrAllSpacing {
            return dismiss(animated: true)
        }
        self.showActivityIndicator()
        ApiProvider.shared.request(fromApi: UserRenameRequest(name: text)) { [weak self] result in
            guard let self else { return }
            self.stopActivityIndicator()
            switch result {
            case .success:
                AuthStore.shared.updateName(text)
                self.dismiss(animated: true)
            case let .failure(error):
                self.toast(error.localizedDescription)
            }
        }
    }
    
    @objc
    func onAvatar() {
        profileUpdate.startUpdateAvatar(from: self)
    }
    
    @objc
    func onAvatarUpdate() {
        let avatarWidth = CGFloat(80)
        let scale = UIScreen.main.scale
        let containerWidth = avatarWidth
        let width = avatarWidth / 2
        let size = CGSize(width: width, height: width).applying(.init(scaleX: scale, y: scale))
        let processor = ResizingImageProcessor(referenceSize: size)
        avatarButton.imageEdgeInsets = .init(inset: (containerWidth - width) / 2)
        avatarButton.kf.setImage(with: AuthStore.shared.user?.avatarUrl,
                                 for: .normal,
                                 options: [.processor(processor)])
        avatarButton.setTitle(nil, for: .normal)
    }
    
    lazy var mainContentView: UIStackView = {
        let spacer = UIView()
        let view = UIStackView(arrangedSubviews: [avatarButton, nickNameTextfield, spacer, finishButton])
        view.axis = .vertical
        view.spacing = 48
        avatarButton.snp.makeConstraints { make in
            make.height.equalTo(200)
        }
        nickNameTextfield.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        finishButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        return view
    }()
    
    lazy var nickNameTextfield: BottomLineTextfield = {
        let tf = BottomLineTextfield()
        
        tf.placeholder = localizeStrings("NewAccountNickNamePlaceholder")
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = .color(type: .text)

        tf.leftViewMode = .always
        let leftContainer = UIView()
        let leftIcon = UIImageView(image: UIImage(named: "profile"))
        leftIcon.contentMode = .center
        leftIcon.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        leftIcon.tintColor = .color(type: .text)
        leftContainer.addSubview(leftIcon)
        leftContainer.frame = leftIcon.bounds
        tf.leftView = leftContainer
        return tf
    }()
    
    lazy var avatarButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "login_default_avatar"), for: .normal)
        btn.setTitle(localizeStrings("NewAccountAvatarPlaceholder"), for: .normal)
        btn.setTitleColor(.color(type: .text), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.verticalCenterImageAndTitleWith(6)
        btn.addTarget(self, action: #selector(onAvatar))
        return btn
    }()
    
    lazy var finishButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton()
        btn.setTitle(localizeStrings("Finish"), for: .normal)
        btn.addTarget(self, action: #selector(onFinish))
        return btn
    }()
}

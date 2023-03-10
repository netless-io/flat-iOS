//
//  CameraPreviewView.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/31.
//  Copyright © 2022 agora.io. All rights reserved.
//

import AVFoundation
import UIKit

extension UIDeviceOrientation {
    func toInterfaceOrientation() -> UIInterfaceOrientation {
        switch self {
        case .unknown:
            return .unknown
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .faceUp:
            return .unknown
        case .faceDown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}

private let sampleQueue = DispatchQueue(label: "io.agora.flat.preview")
class CameraPreviewView: UIView {
    init() {
        super.init(frame: .zero)
        setupViews()
        syncRotate()
        NotificationCenter.default.addObserver(self, selector: #selector(syncRotate), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Turn off device
        if window == nil, isOn {
            turnCamera(on: false)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    @objc func syncRotate() {
        let deviceOrientation = UIDevice.current.orientation.toInterfaceOrientation()
        let windowOrientation = window?.windowScene?.interfaceOrientation ?? .unknown
        let orientation: UIInterfaceOrientation
        
        switch (deviceOrientation, windowOrientation) {
        case (.unknown, .unknown):
            orientation = .landscapeRight
        case (let d, .unknown):
            orientation = d
        case (.unknown, let w):
            orientation = w
        case (_, let w):
            orientation = w
        }
        switch orientation {
        case .unknown:
            return
        case .portrait:
            previewLayer.connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeLeft
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeRight
        @unknown default:
            return
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        previewLayer.backgroundColor = UIColor.color(type: .primary, .weaker).cgColor
    }

    func setupViews() {
        previewLayer.backgroundColor = UIColor.color(type: .primary, .weaker).cgColor
        layer.addSublayer(previewLayer)
        previewLayer.videoGravity = .resizeAspectFill
        clipsToBounds = true
        layer.cornerRadius = 8

        addSubview(avatarContainer)
        avatarContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        avatarContainer.addSubview(avatarImageView)
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 32
        avatarImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(64)
        }
        avatarImageView.kf.setImage(with: AuthStore.shared.user?.avatar)
    }

    var isOn = false

    func turnCamera(on: Bool) {
        if on == isOn { return }
        if on {
            if !didSetupCapture {
                setupCapture()
            } else {
                sampleQueue.async {
                    self.session.startRunning()
                    DispatchQueue.main.async {
                        self.avatarContainer.isHidden = true
                    }
                }
            }
        } else {
            sampleQueue.async {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.avatarContainer.isHidden = false
                }
            }
        }
        isOn = on
    }

    var didSetupCapture = false
    func setupCapture() {
        do {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                logger.error("fetch camera fail")
                return
            }
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(nil, queue: sampleQueue)
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            output.connection(with: .video)?.isEnabled = true
            sampleQueue.async {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.avatarContainer.isHidden = true
                }
            }
            syncRotate()
            didSetupCapture = true
        } catch {
            logger.error("setup capture error \(error)")
        }
    }

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    lazy var avatarContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .color(type: .primary, .weaker)
        return view
    }()

    lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)

    lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        return session
    }()
}

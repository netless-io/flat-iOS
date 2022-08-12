//
//  Theme.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/19.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import Fastboard

enum ThemeStyle: String, Codable, CaseIterable {
    case dark
    case light
    @available(iOS 13, *)
    case auto
    
    var description: String {
        NSLocalizedString("Theme.\(rawValue)", comment: "")
    }
    
    static var `default`: Self {
        if #available(iOS 13.0, *) {
            return .auto
        } else {
            return .light
        }
    }
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        case .auto:
            return .unspecified
        }
    }
    
    static var allCases: [ThemeStyle] {
        if #available(iOS 13.0, *) {
            return [.dark, .light, .auto]
        } else {
            return [.dark, .light]
        }
    }
}

class Theme {
    static let shared = Theme()
    private init() {}
    weak var window: UIWindow? = nil {
        didSet {
            apply(userPreferredStyle ?? .default)
        }
    }
    
    var isDarkBeforeIOS13: Bool {
        if #available(iOS 13.0, *) {
        } else if let style = userPreferredStyle, style == .dark {
            return true
        }
        return false
    }
    
    private(set) var userPreferredStyle: ThemeStyle? {
        get {
            guard let data = UserDefaults.standard.value(forKey: "userPreferredStyle") as? Data
            else { return nil }
            do {
                let info = try JSONDecoder().decode([String: ThemeStyle].self, from: data)
                if let style = info["style"] {
                    return style
                }
                return nil
            }
            catch {
                log(level: .error, log: "get userPreferredStyle, \(error)")
                return nil
            }
        }
        set {
            if let userPreferredStyle = newValue {
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(["style": userPreferredStyle])
                    UserDefaults.standard.setValue(data, forKey: "userPreferredStyle")
                }
                catch {
                    log(level: .error, log: "set userPreferredStyle, \(error)")
                }
            } else {
                UserDefaults.standard.setValue(nil, forKey: "userPreferredStyle")
            }
        }
    }
    
    func updateUserPreferredStyle(_ style: ThemeStyle) {
        userPreferredStyle = style
        apply(style)
    }
    
    fileprivate func apply(_ style: ThemeStyle) {
        if #available(iOS 13.0, *) {
            switch style {
            case .dark:
                window?.overrideUserInterfaceStyle = .dark
            case .light:
                window?.overrideUserInterfaceStyle = .light
            case .auto:
                window?.overrideUserInterfaceStyle = .unspecified
            }
        } else {
            
        }
        applyNavigationBar()
        configProgressHUDAppearance()
        commitUpdate()
    }
    
    fileprivate func commitUpdate() {
        let window = UIApplication.shared.keyWindow
        window?.subviews.forEach {
            $0.removeFromSuperview()
            window?.addSubview($0)
        }
    }
    
    fileprivate func applyNavigationBar() {
        let proxy = UINavigationBar.appearance()
        proxy.tintColor = .subText
        
        if #available(iOS 13.0, *) {} else {
            proxy.isTranslucent = false
            proxy.barTintColor = .whiteBG
            proxy.largeTitleTextAttributes = [
                .foregroundColor: UIColor.text
            ]
            proxy.titleTextAttributes = [
                .foregroundColor: UIColor.text
            ]
        }
    }
}

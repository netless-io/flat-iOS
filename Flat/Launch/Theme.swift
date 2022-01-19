//
//  Theme.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/19.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

enum ThemeStyle: String, Codable, CaseIterable {
    case dark
    case light
    /// Available iOS 13
    case auto
    
    var description: String {
        NSLocalizedString("Theme.\(rawValue)", comment: "")
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
    private(set) var userPreferredStyle: ThemeStyle? {
        get {
            guard let data = UserDefaults.standard.value(forKey: "userPreferredStyle") as? Data
            else { return nil }
            do {
                let style = try JSONDecoder().decode(ThemeStyle.self, from: data)
                return style
            }
            catch {
                return nil
            }
        }
        set {
            if let userPreferredStyle = newValue {
                do {
                    let data = try JSONEncoder().encode(userPreferredStyle)
                    UserDefaults.standard.setValue(data, forKey: "userPreferredStyle")
                }
                catch {
                    print(error)
                }
            } else {
                UserDefaults.standard.setValue(nil, forKey: "userPreferredStyle")
            }
        }
    }
    weak var window: UIWindow?
    init(window: UIWindow) {
        self.window = window
        if let userPreferredStyle = userPreferredStyle {
            apply(userPreferredStyle)
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
            window?.subviews.forEach {
                $0.removeFromSuperview()
                window?.addSubview($0)
            }
        }
    }
}

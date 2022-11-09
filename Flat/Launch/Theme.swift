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
    private(set) var style: ThemeStyle
    private init() {
        func getPreferredStyle() -> ThemeStyle {
            guard let data = UserDefaults.standard.value(forKey: "userPreferredStyle") as? Data
            else { return .default }
            do {
                let info = try JSONDecoder().decode([String: ThemeStyle].self, from: data)
                if let style = info["style"] {
                    return style
                }
                return .default
            }
            catch {
                logger.error("get userPreferredStyle, \(error)")
                return .default
            }
        }
        style = getPreferredStyle()
    }
    weak var window: UIWindow? = nil {
        didSet {
            apply(style)
        }
    }
    
    var isDarkBeforeIOS13: Bool {
        if #available(iOS 13.0, *) {
        } else if style == .dark {
            return true
        }
        return false
    }
    
    fileprivate func setStoredPreferredStyle(_ newValue: ThemeStyle) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(["style": newValue])
            UserDefaults.standard.setValue(data, forKey: "userPreferredStyle")
        }
        catch {
            logger.error("set userPreferredStyle, \(error)")
        }
    }
    
    func updateUserPreferredStyle(_ style: ThemeStyle) {
        self.style = style
        apply(style)
        setStoredPreferredStyle(style)
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
        applyFastboard(style)
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
        proxy.tintColor = .color(type: .text)
        
        if #available(iOS 13.0, *) {} else {
            proxy.isTranslucent = false
            proxy.barTintColor = .color(type: .background)
            proxy.largeTitleTextAttributes = [
                .foregroundColor: UIColor.color(type: .text)
            ]
            proxy.titleTextAttributes = [
                .foregroundColor: UIColor.color(type: .text)
            ]
        }
    }
    
    fileprivate func applyFastboard(_ style: ThemeStyle) {
        let flatTheme: FastRoomThemeAsset
        switch style {
        case .dark:
            flatTheme = FastRoomDefaultTheme.defaultDarkTheme
        case .light:
            flatTheme = FastRoomDefaultTheme.defaultLightTheme
        case .auto:
            if #available(iOS 13, *) {
                flatTheme = FastRoomDefaultTheme.defaultAutoTheme
            } else {
                fatalError("never")
            }
        }
        
        flatTheme.panelItemAssets.normalIconColor = .color(type: .text)
        flatTheme.panelItemAssets.selectedBackgroundEdgeinset = isCompact() ? .zero : .init(inset: -4)
        flatTheme.panelItemAssets.selectedBackgroundCornerRadius = isCompact() ? 0 : 8
        flatTheme.panelItemAssets.selectedIconBgColor = isCompact() ? .clear : .color(type: .primary, .weak)
        
        flatTheme.controlBarAssets.borderColor = .borderColor
        flatTheme.controlBarAssets.effectStyle = nil
        flatTheme.controlBarAssets.backgroundColor = .color(type: .background)
        
        FastRoomThemeManager.shared.apply(flatTheme)
    }
}

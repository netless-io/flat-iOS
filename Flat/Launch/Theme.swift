//
//  Theme.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/19.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Fastboard
import Foundation

enum ThemeStyle: String, Codable, CaseIterable {
    case dark
    case light
    case auto

    var description: String {
        localizeStrings("Theme.\(rawValue)")
    }

    static var `default`: Self { .auto }

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

    static var allCases: [ThemeStyle] { [.dark, .light, .auto] }
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
            } catch {
                logger.error("get userPreferredStyle, \(error)")
                return .default
            }
        }
        style = getPreferredStyle()
    }
    
    func setupWindowTheme(_ window: UIWindow?) {
        apply(style, window: window)
    }
    
    func updateUserPreferredStyle(_ style: ThemeStyle) {
        self.style = style
        setStoredPreferredStyle(style)
        SceneManager.shared.windowMap.map(\.value).forEach { apply(style, window: $0) }
        SceneManager.shared.refreshMultiWindowPreview()
    }
    
    private func setStoredPreferredStyle(_ newValue: ThemeStyle) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(["style": newValue])
            UserDefaults.standard.setValue(data, forKey: "userPreferredStyle")
        } catch {
            logger.error("set userPreferredStyle, \(error)")
        }
    }

    private func apply(_ style: ThemeStyle, window: UIWindow?) {
        switch style {
        case .dark:
            window?.overrideUserInterfaceStyle = .dark
        case .light:
            window?.overrideUserInterfaceStyle = .light
        case .auto:
            window?.overrideUserInterfaceStyle = .unspecified
        }
        applyNavigationBar()
        configProgressHUDAppearance()
        applyFastboard(style, for: window)
        commitUpdate(for: window)
    }

    private func commitUpdate(for window: UIWindow?) {
        window?.subviews.forEach {
            $0.removeFromSuperview()
            window?.addSubview($0)
        }
    }

    private func applyNavigationBar() {
        let proxy = UINavigationBar.appearance()
        proxy.tintColor = .color(type: .text)
    }

    private func applyFastboard(_ style: ThemeStyle, for window: UIWindow?) {
        let hasCompact = window?.traitCollection.hasCompact ?? true
        FastRoomControlBar.appearance().commonRadius = hasCompact ? 8 : 4
        FastRoomControlBar.appearance().itemWidth = hasCompact ? 40 : 48
        
        let flatTheme: FastRoomThemeAsset
        switch style {
        case .dark:
            flatTheme = FastRoomDefaultTheme.defaultDarkTheme
        case .light:
            flatTheme = FastRoomDefaultTheme.defaultLightTheme
        case .auto:
            flatTheme = FastRoomDefaultTheme.defaultAutoTheme
        }

        flatTheme.panelItemAssets.normalIconColor = .color(type: .text)
        flatTheme.panelItemAssets.selectedBackgroundEdgeinset = hasCompact ? .zero : .init(inset: -4)
        flatTheme.panelItemAssets.selectedBackgroundCornerRadius = hasCompact ? 0 : 8
        flatTheme.panelItemAssets.selectedIconBgColor = hasCompact ? .clear : .color(type: .primary, .weak)
        flatTheme.panelItemAssets.selectedColorItemBgColor = .color(type: .primary, .weak)

        flatTheme.controlBarAssets.borderColor = .borderColor
        flatTheme.controlBarAssets.effectStyle = nil
        flatTheme.controlBarAssets.backgroundColor = .color(type: .background)

        FastRoomThemeManager.shared.apply(flatTheme)
    }
}

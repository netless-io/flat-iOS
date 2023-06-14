//
//  Theme.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/19.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Fastboard
import Foundation
import Whiteboard

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

    var schemeStringForWeb: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .auto:
            guard let style = SceneManager.shared.windowMap.randomElement()?.value.traitCollection.userInterfaceStyle
            else { return "light" }
            switch style {
            case .light: return "light"
            case .dark: return "dark"
            default: return "light"
            }
        }
    }

    static var allCases: [ThemeStyle] { [.dark, .light, .auto] }
}

enum WhiteboardStyle {
    case `default`
    case hex(String)
    
    static var list: [WhiteboardStyle] {
        [
            .default,
            .hex("#064D6D"),
            .hex("#49585F"),
            .hex("#446550")
        ]
    }
    
    var image: UIImage? {
        switch self {
        case .default:
            return UIImage(named: "whiteboard_bg_default")
        case .hex(let string):
            return UIImage(named: "whiteboard_bg_\(string)")
        }
    }
    
    var localizedString: String {
        switch self {
        case .default:
            return localizeStrings("DefaultWhiteboardStyle")
        case .hex(let string):
            return localizeStrings("WhiteboardStyle\(string)")
        }
    }
    
    var string: String {
        switch self {
        case .default:
            return "default"
        case .hex(let string):
            return string
        }
    }
    
    func whiteboardTraitCollectionDidChangeResolve(_ traitCollection: UITraitCollection, fastRoom: FastRoom) {
        switch self {
        case .default:
            fastRoom.view.whiteboardView.backgroundColor = UIColor.color(type: .background).resolvedColor(with: traitCollection)
        case .hex(let string):
            fastRoom.view.whiteboardView.backgroundColor = .init(hexString: string)
        }
    }
    
    var teleboxTheme: WhiteTeleBoxManagerThemeConfig? {
        switch self {
        case .default:
            return nil
        case .hex(let string):
            let config = WhiteTeleBoxManagerThemeConfig()
            config.managerStageBackground = string
            config.managerContainerBackground = string
            return config
        }
    }
    
    init(string: String) {
        if string.starts(with: "#") {
            self = .hex(string)
        } else {
            self = .default
        }
    }
}

class Theme {
    static let shared = Theme()
    private(set) var style: ThemeStyle
    private(set) var whiteboardStyle: WhiteboardStyle
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
        func getWhiteboardStyle() -> WhiteboardStyle {
            guard let string = UserDefaults.standard.value(forKey: "whiteboardStyle") as? String
            else { return .default }
            return .init(string: string)
        }
        whiteboardStyle = getWhiteboardStyle()
        style = getPreferredStyle()
    }

    func setupWindowTheme(_ window: UIWindow?) {
        apply(style, window: window)
    }
    
    func updateUserPreferredStyle(_ style: ThemeStyle?, whiteboardStyle: WhiteboardStyle?) {
        if let whiteboardStyle {
            self.whiteboardStyle = whiteboardStyle
            setStoredWhiteboardStyle(whiteboardStyle)
        }
        if let style {
            self.style = style
            setStoredPreferredStyle(style)
        }
        SceneManager.shared.windowMap.map(\.value).forEach { apply(self.style, window: $0) }
        SceneManager.shared.refreshMultiWindowPreview()
    }

    private func setStoredWhiteboardStyle(_ newValue: WhiteboardStyle) {
        UserDefaults.standard.setValue(newValue.string, forKey: "whiteboardStyle")
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

        if let teleboxTheme = whiteboardStyle.teleboxTheme {
            flatTheme.teleboxTheme = teleboxTheme
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

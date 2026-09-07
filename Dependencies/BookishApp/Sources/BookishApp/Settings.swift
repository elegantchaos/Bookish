// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Settings

/// Boolean setting keys.
@MainActor extension AppSettingKey where Value == Bool {
  /// UserDefaults key for whether the app is in advanced mode.
  /// In this mode we show extra, more nerdy options, layouts, indexes, etc.
  public static let isAdvancedMode = AppSettingKey("AdvancedMode", defaultValue: false)

  /// UserDefaults key for whether the app is in developer mode.
  /// In this mode we show extra debugging information, commands, etc.
  public static let isDeveloperMode = AppSettingKey("DeveloperMode", defaultValue: false)

}

//@MainActor public extension AppSettingKey where Value == MenuBarExtraMode {
//  /// UserDefaults key for the macOS menu bar extra display mode.
//  static let menuBarExtraMode = AppSettingKey("MenuBarExtraMode", defaultValue: .redWhenFailing)
//}
//
//@MainActor public extension AppSettingKey where Value == RefreshRate {
//  /// UserDefaults key for the configured polling interval.
//  static let refreshInterval = AppSettingKey("RefreshInterval", defaultValue: RefreshRate.automatic)
//}
//
//@MainActor public extension AppSettingKey where Value == SortMode {
//  /// UserDefaults key for the sort mode setting.
//  static let sortMode = AppSettingKey("SortMode", defaultValue: SortMode.state)
//}
//
//@MainActor public extension AppSettingKey where Value == DisplaySize {
//  /// UserDefaults key for the display density setting.
//  static let displaySize = AppSettingKey("DisplaySize", defaultValue: .automatic)
//}
//
///// Data setting keys.
//@MainActor public extension AppSettingKey where Value == Data {
//  /// UserDefaults key for the hotkey combo data.
//  static let hotKeyCombo = AppSettingKey("hotKeyCombo", defaultValue: Data())
//}

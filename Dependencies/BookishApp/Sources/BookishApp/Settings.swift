// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Settings

@MainActor extension AppSettingKey where Value == Bool {
  /// Whether advanced controls, layouts, and indexes are visible.
  public static let isAdvancedMode = AppSettingKey("AdvancedMode", defaultValue: false)

  /// Whether developer diagnostics and commands are visible.
  public static let isDeveloperMode = AppSettingKey("DeveloperMode", defaultValue: false)
}

@MainActor extension AppSettingKey where Value == BookRecognitionProvider {
  /// The default recognition service to use.
  public static let bookRecognitionProvider = AppSettingKey(
    "BookRecognitionProvider",
    defaultValue: .fake
  )
}

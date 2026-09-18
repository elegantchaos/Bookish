// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import BookishRecognition
import Foundation
import Settings

@MainActor extension AppSettingKey where Value == Bool {
  /// Whether advanced controls, layouts, and indexes are visible.
  public static let isAdvancedMode = AppSettingKey("AdvancedMode", defaultValue: false)

  /// Whether developer diagnostics and commands are visible.
  public static let isDeveloperMode = AppSettingKey("DeveloperMode", defaultValue: false)

  /// Whether to scan for barcodes when using the camera in the capture mode.
  public static let scanForBarcodes = AppSettingKey("BarcodeScanning", defaultValue: true)
}

@MainActor extension AppSettingKey where Value == BookRecognitionProviderID {
  /// The default recognition provider to use.
  public static let bookRecognitionProvider = AppSettingKey(
    "BookRecognitionProvider", defaultValue: .foundationInCloud
  )
}

@MainActor extension AppSettingKey where Value == BookLookupProviderID {
  /// The default lookup provider to use.
  public static let bookLookupProvider = AppSettingKey(
    "BookLookupProvider", defaultValue: .openLibrary
  )
}

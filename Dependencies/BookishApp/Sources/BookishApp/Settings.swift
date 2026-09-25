// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import BookishRecognition
import BookishRecord
import Foundation
import Settings

@MainActor extension AppSettingKey where Value == Bool {
  /// Whether to scan for barcodes when using the camera in the capture mode.
  public static let scanForBarcodes = AppSettingKey("BarcodeScanning", defaultValue: true)
}

@MainActor extension AppSettingKey where Value == BookishFeatureMode {
  /// How much optional and diagnostic functionality is visible.
  public static let featureMode = AppSettingKey("FeatureMode", defaultValue: .normal)
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

@MainActor extension AppSettingKey where Value == BookishNavigationSelection {
  /// The sidebar route to restore after the application launches.
  public static let lastNavigationSelection = AppSettingKey(
    "LastNavigationSelection", defaultValue: .automatic
  )
}

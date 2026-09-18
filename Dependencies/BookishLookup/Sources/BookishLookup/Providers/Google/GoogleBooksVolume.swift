// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Decodes one Google Books volume and its provider-assigned identifier.
struct GoogleBooksVolume: Codable {
  /// Google's stable identifier for the volume.
  let id: String

  /// The bibliographic metadata supplied for the volume.
  let volumeInfo: GoogleBooksVolumeInfo
}

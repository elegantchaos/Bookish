// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Identifies a recognition provider compiled into Bookish.
public enum BookRecognitionProviderID: String, Codable, Sendable, Hashable, CaseIterable {
  /// Identifies the deterministic provider used for previews and tests.
  case fake

  /// Identifies the OCR-backed recognition provider.
  case ocrOnly

  /// Identifies the on-device Foundation Models provider.
  case foundationOnDevice

  /// Identifies the Foundation Models cloud-compute provider.
  case foundationInCloud

  /// Identifies the OpenAI recognition provider.
  case openAI
}

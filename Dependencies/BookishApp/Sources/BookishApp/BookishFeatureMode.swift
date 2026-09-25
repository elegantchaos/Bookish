// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// How much optional and diagnostic functionality the app exposes.
public enum BookishFeatureMode: String, Codable, Sendable, Hashable, CaseIterable {
  /// Only the standard user-facing features are visible.
  case normal

  /// Advanced controls, layouts, and indexes are visible.
  case advanced

  /// Advanced features plus developer diagnostics and commands are visible.
  case development

  /// The user-facing name of the mode.
  public var label: String {
    switch self {
    case .normal: "Normal"
    case .advanced: "Advanced"
    case .development: "Development"
    }
  }

  /// Whether advanced controls, layouts, and indexes are visible.
  public var showsAdvanced: Bool { self != .normal }

  /// Whether developer diagnostics and commands are visible.
  public var showsDevelopment: Bool { self == .development }
}

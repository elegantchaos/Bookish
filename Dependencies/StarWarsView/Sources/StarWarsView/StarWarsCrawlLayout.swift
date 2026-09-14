// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Selects the typographic treatment for crawl text.
public enum StarWarsCrawlLayout: Sendable {
  /// Uses a spacious, centered SwiftUI text layout.
  case loose

  /// Uses compact, fully justified paragraphs like the original film crawl.
  case denseJustified
}

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Performs the HTTP request required by a book recognizer.
public protocol BookRecognitionTransport: Sendable {
  /// Sends a request and returns its response data and metadata.
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: BookRecognitionTransport {}

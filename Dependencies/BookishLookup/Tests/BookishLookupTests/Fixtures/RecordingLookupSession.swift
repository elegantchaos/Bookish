// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Synchronization

/// Supplies canned responses through an isolated URL session and records its request.
final class RecordingLookupSession: Sendable {
  /// The concrete session injected into a lookup provider.
  let session: URLSession

  /// Routes protocol callbacks to this fixture.
  private let identifier = UUID().uuidString

  /// The data returned to the provider.
  let responseData: Data

  /// Protects request recording across URLSession callbacks and test assertions.
  let recordedRequest = Mutex<URLRequest?>(nil)

  /// The request sent by the provider.
  var request: URLRequest? { recordedRequest.withLock { $0 } }

  /// Configures a session that cannot make live network requests.
  init(responseData: Data) {
    self.responseData = responseData
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [LookupURLProtocol.self]
    configuration.httpAdditionalHeaders = [LookupURLProtocol.fixtureHeader: identifier]
    session = URLSession(configuration: configuration)
    LookupURLProtocol.fixtures.withLock { $0[identifier] = self }
  }

  /// Ends the session and removes its callback registration.
  func close() {
    session.invalidateAndCancel()
    LookupURLProtocol.fixtures.withLock { $0[identifier] = nil }
  }
}

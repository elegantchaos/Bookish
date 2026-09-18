// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Synchronization

/// Intercepts requests from `RecordingLookupSession` instances.
final class LookupURLProtocol: URLProtocol {
  /// The header that associates a request with its fixture.
  static let fixtureHeader = "X-Bookish-Lookup-Test-Fixture"

  /// The active fixtures, keyed by their session identifier.
  static let fixtures = Mutex<[String: RecordingLookupSession]>([:])

  /// Handles every request made through the fixture session.
  override class func canInit(with _: URLRequest) -> Bool { true }

  /// Leaves the request unchanged for provider assertions.
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  /// Records the request and completes with the fixture's response data.
  override func startLoading() {
    guard let identifier = request.value(forHTTPHeaderField: Self.fixtureHeader),
      let fixture = Self.fixtures.withLock({ $0[identifier] }),
      let url = request.url,
      let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    fixture.recordedRequest.withLock { $0 = request }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: fixture.responseData)
    client?.urlProtocolDidFinishLoading(self)
  }

  /// Responses complete synchronously, so cancellation has no work to perform.
  override func stopLoading() {}
}

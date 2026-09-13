import Foundation
import Synchronization

/// Gives each test an isolated URLSession that records requests without contacting a server.
final class RecordingRecognitionSession: Sendable {
  /// The concrete session injected into the recognizer.
  let session: URLSession

  /// Routes URLProtocol callbacks to this fixture while tests run in parallel.
  private let identifier = UUID().uuidString

  /// The canned response body.
  fileprivate let responseData: Data

  /// Protects request recording across URLSession callbacks and test assertions.
  fileprivate let recordedRequest = Mutex<URLRequest?>(nil)

  /// The latest request, including its body for payload assertions.
  var request: URLRequest? { recordedRequest.withLock { $0 } }

  /// Configures interception only for this session, without global URLProtocol registration.
  init(responseData: Data) {
    self.responseData = responseData
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RecognitionURLProtocol.self]
    configuration.httpAdditionalHeaders = [RecognitionURLProtocol.fixtureHeader: identifier]
    session = URLSession(configuration: configuration)
    RecognitionURLProtocol.fixtures.withLock { $0[identifier] = self }
  }

  /// Releases the session and its callback registration; call in the test's defer block.
  func close() {
    session.invalidateAndCancel()
    RecognitionURLProtocol.fixtures.withLock { $0[identifier] = nil }
  }
}

/// Implements Foundation's request interception hook for the fixture sessions only.
private final class RecognitionURLProtocol: URLProtocol {
  /// Identifies each fixture without changing the recognizer's API request construction.
  static let fixtureHeader = "X-Bookish-Test-Fixture"

  /// URLProtocol creates its own instances, so callbacks find their fixture through this locked map.
  static let fixtures = Mutex<[String: RecordingRecognitionSession]>([:])

  /// Intercepts every request, including unexpected ones, to prevent live networking.
  override class func canInit(with request: URLRequest) -> Bool { true }

  /// Preserves the request for the recognizer's request-format assertions.
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  /// Records the request and completes it synchronously with a canned HTTP response.
  override func startLoading() {
    guard let identifier = request.value(forHTTPHeaderField: Self.fixtureHeader),
      let fixture = Self.fixtures.withLock({ $0[identifier] }),
      let url = request.url,
      let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      var recorded = request
      // URLSession can convert an HTTP body into a stream before handing it to URLProtocol.
      if recorded.httpBody == nil, let stream = recorded.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
          let count = stream.read(&buffer, maxLength: buffer.count)
          guard count >= 0 else { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
          if count == 0 { break }
          body.append(contentsOf: buffer.prefix(count))
        }
        recorded.httpBody = body
      }
      fixture.recordedRequest.withLock { $0 = recorded }
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: fixture.responseData)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  /// Responses complete synchronously, so no background work needs cancellation.
  override func stopLoading() {}
}

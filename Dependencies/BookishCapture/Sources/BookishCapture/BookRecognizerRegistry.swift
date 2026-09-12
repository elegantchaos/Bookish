// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Creates Bookish's currently supported AI recognition services.
public class BookRecognizerRegistry {
  var recognisers: [String:any BookRecognizer] = [:]

  /// Creates a factory that obtains the OpenAI key from Keychain.
  public init() {
  }

  public func registerStandardRecognizers() {
    register(FakeBookRecognizer())
    register(OnDeviceBookRecognizer())
    register(CloudComputeBookRecognizer())
    
  }
  
  public func register(_ recognizer: any BookRecognizer) {
    recognisers[recognizer.id] = recognizer
  }
  
  public func recognizer(forID id: String) -> BookRecognizer {
    recognisers[id]!
  }
  
  public var recognizerIDs: [String] {
    recognisers.keys.sorted()
  }
  
  public var recognizers: [any BookRecognizer] {
    Array(recognisers.values)
  }

}

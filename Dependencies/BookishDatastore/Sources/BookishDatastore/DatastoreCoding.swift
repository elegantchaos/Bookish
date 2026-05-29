import Foundation

extension JSONEncoder {
  /// Creates the stable encoder used by the JSON prototype stores.
  static func bookishDatastoreEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}

extension JSONDecoder {
  /// Creates the decoder used by the JSON prototype stores.
  static func bookishDatastoreDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}

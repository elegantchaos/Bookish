import Foundation

extension JSONEncoder {
  /// Creates the stable encoder used by the JSON local stores.
  ///
  /// Dates are written as raw reference-date intervals so that they round-trip exactly;
  /// mutation replay order depends on sub-second creation times.
  static func bookishDatastoreEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .deferredToDate
    return encoder
  }
}

extension JSONDecoder {
  /// Creates the decoder used by the JSON local stores.
  static func bookishDatastoreDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .deferredToDate
    return decoder
  }
}

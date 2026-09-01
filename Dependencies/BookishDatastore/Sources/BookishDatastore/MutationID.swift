import Foundation

/// Identifies a mutation record.
public struct MutationID: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
  /// The stable raw identifier used for persistence and interchange.
  public let rawValue: String
  
  /// Creates an identifier from an existing raw value.
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  /// Creates a new unique mutation identifier.
  public init() {
    self.rawValue = UUID().uuidString
  }
  
  /// A readable representation of the identifier.
  public var description: String {
    rawValue
  }
}

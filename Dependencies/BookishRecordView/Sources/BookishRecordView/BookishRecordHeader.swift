import Foundation

/// The user-facing identity fields displayed above a record's properties.
public struct BookishRecordHeader: Equatable, Sendable {
  /// The primary title of the record, when the configured property contains a string.
  public let title: String?

  /// The secondary title of the record, when the configured property contains a string.
  public let subtitle: String?

  /// The remote image URL used for the record thumbnail, when available and valid.
  public let thumbnailURL: URL?

  /// Creates a record header from its resolved display values.
  public init(title: String?, subtitle: String?, thumbnailURL: URL?) {
    self.title = title
    self.subtitle = subtitle
    self.thumbnailURL = thumbnailURL
  }

  /// Indicates whether the record has no visible header content.
  public var isEmpty: Bool {
    title == nil && subtitle == nil && thumbnailURL == nil
  }
}

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Standard kinds used by Bookish catalogue records.
public enum BookishRecordKind {
  /// A generic record with no more specific catalogue kind.
  public static let record = "record"

  /// A catalogue book.
  public static let book = "book"

  /// A person, including authors and illustrators.
  public static let person = "person"

  /// An organisation, including publishers and imprints.
  public static let organisation = "organisation"

  /// A book series.
  public static let series = "series"

  /// An ordered or unordered collection of records.
  public static let list = "list"

  /// A relationship record that carries metadata about a connection.
  public static let relationship = "relationship"

  /// A record that defines a presentation layout.
  public static let layout = "layout"

  /// A record that defines a browser index.
  public static let index = "index"

  /// A record that defines property presentations for a record kind.
  public static let presentation = "presentation"

  /// A marker record indicating that initial application seeding has run.
  public static let seedMarker = "seedMarker"
}

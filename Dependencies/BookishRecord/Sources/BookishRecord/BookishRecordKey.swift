// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Standard property keys used by Bookish catalogue records.
public enum BookishRecordKey {
  /// A record's display name.
  public static let name = "name"

  /// Whether a configuration record is intended only for debug browsing.
  public static let debugOnly = "debugOnly"

  /// An integer position used for stable user-facing ordering.
  public static let position = "position"

  /// The identifier of the system that supplied the record.
  public static let source = "source"

  /// The source-system identifier retained during import.
  public static let importedID = "importedID"

  /// An ordered list of author record links.
  public static let authors = "authors"

  /// An ordered list of illustrator record links.
  public static let illustrators = "illustrators"

  /// An ordered list of publisher record links.
  public static let publishers = "publishers"

  /// A direct link to a series record.
  public static let series = "series"

  /// A book's bibliographic number within a series.
  public static let seriesPosition = "seriesPosition"

  /// The edition or physical format of a book.
  public static let format = "format"

  /// A book's subtitle.
  public static let subtitle = "subtitle"

  /// An Amazon Standard Identification Number.
  public static let asin = "asin"

  /// A Dewey Decimal Classification value.
  public static let dewey = "dewey"

  /// An International Standard Book Number.
  public static let isbn = "isbn"

  /// A book's page count.
  public static let pages = "pages"

  /// A physical height measurement.
  public static let height = "height"

  /// A physical width measurement.
  public static let width = "width"

  /// A physical length measurement.
  public static let length = "length"

  /// The date on which a record was added to its source catalogue.
  public static let addedDate = "added"

  /// The date on which a record was last changed in its source catalogue.
  public static let modifiedDate = "modified"

  /// A book's publication date.
  public static let publishedDate = "published"

  /// The JSON representation of the unmodified source record used to create this record.
  public static let originalData = "originalData"

  /// A list of edition descriptions.
  public static let editions = "editions"

  /// A list of genre descriptions.
  public static let genres = "genres"

  /// A list of cover-image URLs.
  public static let imageURLs = "imageURLs"

  /// A user-maintained reading or ownership status.
  public static let status = "status"

  /// A free-form note.
  public static let note = "note"

  /// An ordered list of record links contained by a list record.
  public static let items = "items"

  /// An ordered list of keys displayed by a layout record.
  public static let fields = "fields"

  /// A list of fields suppressed by a layout, including fields expanded by `allOtherFields`.
  public static let excludedFields = "excludedFields"

  /// A link to property presentation metadata that overrides a layout's default cascade.
  public static let presentation = "presentation"

  /// A layout field token that expands to every property not already listed.
  public static let allOtherFields = "*"

  /// An advisory list of record kinds an index or layout is designed to surface.
  public static let types = "types"

  /// A type-list token that matches any record kind.
  public static let allTypes = "*"

  /// A link to the layout used when records are viewed through an index.
  public static let layout = "layout"

  /// A stored query description.
  public static let query = "query"
}

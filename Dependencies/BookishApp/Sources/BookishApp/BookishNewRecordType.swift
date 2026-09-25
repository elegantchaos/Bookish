/// Standard user-creatable catalogue record kinds.
public enum BookishNewRecordType: String, CaseIterable, Sendable {
  case book
  case person
  case organisation
  case series
  case list

  /// The name used for a new untitled record.
  public var initialName: String {
    switch self {
    case .book: "New Book"
    case .person: "New Person"
    case .organisation: "New Organisation"
    case .series: "New Series"
    case .list: "New List"
    }
  }

  /// The label shown in the New menu.
  public var menuName: String {
    switch self {
    case .book: "Book"
    case .person: "Person"
    case .organisation: "Organisation"
    case .series: "Series"
    case .list: "List"
    }
  }

  /// The symbol for the record creation action.
  public var systemImage: String {
    switch self {
    case .book: "book.closed"
    case .person: "person"
    case .organisation: "building.2"
    case .series: "square.stack.3d.up"
    case .list: "list.bullet"
    }
  }
}

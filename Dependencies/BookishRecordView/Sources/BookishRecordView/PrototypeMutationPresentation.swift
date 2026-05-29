import BookishDatastore
import Foundation

/// A display-ready representation of a datastore mutation for prototype views.
public struct PrototypeMutationPresentation: Equatable, Sendable {
  /// The original mutation record being presented.
  public let mutation: MutationRecord

  /// Creates a mutation presentation.
  public init(mutation: MutationRecord) {
    self.mutation = mutation
  }

  /// A compact operation title for rows and navigation.
  public var title: String {
    switch mutation.operation {
    case .upsertRecord(let record):
      "Upsert \(record.kind)"
    case .setProperty(_, _, let key, _):
      "Set \(label(for: key))"
    case .deleteProperty(_, let key):
      "Delete \(label(for: key))"
    case .deleteRecord:
      "Delete Record"
    }
  }

  /// A secondary summary of the affected record.
  public var subtitle: String {
    switch mutation.operation {
    case .upsertRecord(let record):
      "\(record.kind) · \(record.id.rawValue)"
    case .setProperty(let recordID, let kind, _, _):
      "\(kind) · \(recordID.rawValue)"
    case .deleteProperty(let recordID, _):
      recordID.rawValue
    case .deleteRecord(let recordID):
      recordID.rawValue
    }
  }

  /// A compact creation timestamp.
  public var createdAtText: String {
    mutation.createdAt.formatted(date: .abbreviated, time: .standard)
  }

  /// The fields visible in the mutation detail view.
  public var fields: [PrototypeRecordField] {
    switch mutation.operation {
    case .upsertRecord(let record):
      [
        field("operation", "Operation", "Upsert Record"),
        field("recordID", "Record ID", record.id.rawValue),
        field("kind", "Kind", record.kind),
        field("properties", "Properties", record.properties.count.formatted()),
      ]

    case .setProperty(let recordID, let kind, let key, let value):
      [
        field("operation", "Operation", "Set Property"),
        field("recordID", "Record ID", recordID.rawValue),
        field("kind", "Kind", kind),
        field("property", "Property", key),
        field("value", "Value", value.displayString),
      ]

    case .deleteProperty(let recordID, let key):
      [
        field("operation", "Operation", "Delete Property"),
        field("recordID", "Record ID", recordID.rawValue),
        field("property", "Property", key),
      ]

    case .deleteRecord(let recordID):
      [
        field("operation", "Operation", "Delete Record"),
        field("recordID", "Record ID", recordID.rawValue),
      ]
    }
  }

  private func label(for key: String) -> String {
    key
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }

  private func field(_ id: String, _ label: String, _ value: String) -> PrototypeRecordField {
    PrototypeRecordField(key: id, label: label, value: value)
  }
}

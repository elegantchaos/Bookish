// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A storage-neutral value that can be assigned to a Bookish record property.
public indirect enum BookishRecordValue: Codable, Equatable, Sendable {
  /// A string value.
  case string(String)

  /// A whole-number value.
  case integer(Int)

  /// A floating-point value.
  case double(Double)

  /// A boolean value.
  case bool(Bool)

  /// A date value.
  case date(Date)

  /// A link to another record.
  case record(BookishRecordID)

  /// A reference to immutable out-of-line blob data.
  case blob(BookishBlobReference)

  /// An ordered list of values.
  case list([BookishRecordValue])

  /// An opaque JSON payload encoded from a small Codable value.
  case encoded([String: BookishEncodedValue])

  /// A record tombstone marker.
  case tombstone

  /// A property deletion marker.
  case deletion

  /// A conflict marker containing alternative values.
  case conflict([BookishRecordValue])
}

extension BookishRecordValue {
  /// Returns the contained string when this value is `.string`.
  public var stringValue: String? {
    guard case .string(let value) = self else {
      return nil
    }

    return value
  }

  /// Returns the contained integer when this value is `.integer`.
  public var integerValue: Int? {
    guard case .integer(let value) = self else {
      return nil
    }

    return value
  }

  /// Returns the contained double when this value is `.double`.
  public var doubleValue: Double? {
    guard case .double(let value) = self else {
      return nil
    }

    return value
  }

  /// Returns the contained boolean when this value is `.bool`.
  public var boolValue: Bool? {
    guard case .bool(let value) = self else {
      return nil
    }

    return value
  }

  /// Returns the contained date when this value is `.date`.
  public var dateValue: Date? {
    guard case .date(let value) = self else {
      return nil
    }

    return value
  }

  /// Returns the contained record identifier when this value is `.record`.
  public var recordValue: BookishRecordID? {
    guard case .record(let value) = self else {
      return nil
    }

    return value
  }

  /// Returns the contained list when this value is `.list`.
  public var listValue: [BookishRecordValue]? {
    guard case .list(let value) = self else {
      return nil
    }

    return value
  }
}

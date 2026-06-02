// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors raised by Bookish interchange coding.
public enum BookishCodingError: Error, Equatable {
  /// The top-level JSON value is not an interchange object.
  case invalidFile

  /// The file does not contain a record array.
  case missingRecords

  /// A record does not contain an identifier field.
  case missingRecordID

  /// A record identifier is malformed.
  case invalidRecordID(String)

  /// A shorthand record reference is malformed.
  case invalidRecordReference(String)

  /// A record value object is missing its record identifier.
  case missingRecordReferenceID

  /// A blob value object is missing its blob identifier.
  case missingBlobID

  /// A date value object is malformed.
  case invalidDate

  /// A conflict value object is malformed.
  case invalidConflict

  /// An explicit record value kind is unknown.
  case unknownRecordValueKind(String)

  /// A JSON object property value does not contain the record value marker.
  case untaggedObjectValue

  /// The root value is malformed.
  case invalidRoot

  /// The JSON value cannot be represented as a Bookish record value.
  case unsupportedValue(String)

  public static func == (lhs: BookishCodingError, rhs: BookishCodingError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidFile, .invalidFile),
      (.missingRecords, .missingRecords),
      (.missingRecordID, .missingRecordID),
      (.missingRecordReferenceID, .missingRecordReferenceID),
      (.missingBlobID, .missingBlobID),
      (.invalidDate, .invalidDate),
      (.invalidConflict, .invalidConflict),
      (.untaggedObjectValue, .untaggedObjectValue),
      (.invalidRoot, .invalidRoot):
      return true

    case (.invalidRecordID(let lhs), .invalidRecordID(let rhs)),
      (.invalidRecordReference(let lhs), .invalidRecordReference(let rhs)),
      (.unknownRecordValueKind(let lhs), .unknownRecordValueKind(let rhs)):
      return lhs == rhs

    case (.unsupportedValue(let lhs), .unsupportedValue(let rhs)):
      return lhs == rhs

    default:
      return false
    }
  }
}

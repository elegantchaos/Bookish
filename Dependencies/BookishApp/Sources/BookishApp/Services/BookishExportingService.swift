// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCoding
import BookishDatastore
import BookishRecord
import Commands
import Foundation
import Observation

/// Produces interchange files from stored records and presents the export sheet.
@MainActor
public final class BookishExportingService {
  public private(set) lazy var state = State(service: self)

  /// The storage service supplying materialised records for export.
  private let storageService: BookishStorageService

  /// The navigation service that supplies the export root and visible records.
  private let navigation: any BookishNavigationService.API

  /// The status service used to report export outcomes.
  fileprivate let statusService: any BookishStatusService.API

  /// Creates an exporter that reads from the supplied storage service.
  public init(
    storageService: BookishStorageService,
    navigation: any BookishNavigationService.API,
    statusService: any BookishStatusService.API
  ) {
    self.storageService = storageService
    self.navigation = navigation
    self.statusService = statusService
  }

  /// Encodes every materialised record and associates the supplied record as the interchange root.
  func interchangeData(root: BookishRecordID?) async throws -> Data {
    let records = try await storageService.records(matching: RecordQuery(sort: [.kind, .id]))
    return try BookishInterchangeCodec().encode(
      BookishInterchangeFile(root: root, records: records))
  }
}

extension BookishExportingService {
  /// Requests interchange export from commands.
  @MainActor
  public protocol API: AnyObject {
    /// Whether records are available for interchange export.
    var hasExportableRecords: Bool { get }
    /// Encodes the records and presents the export sheet.
    func requestInterchangeExport() async
  }

  @MainActor
  public protocol Access: CommandCentre {
    var exportingAPI: any API { get }
  }

  @MainActor
  @Observable
  public final class State {
    @ObservationIgnored private unowned let service: BookishExportingService

    /// Whether the interchange export file picker is visible.
    public var isExportingInterchange = false

    /// The document currently being exported.
    public fileprivate(set) var interchangeExportDocument = BookishInterchangeDocument()

    fileprivate init(service: BookishExportingService) {
      self.service = service
    }

    /// Reports successful completion of the interchange export panel.
    public func didExportInterchange() {
      service.statusService.report(message: "Exported interchange file")
    }
  }
}

extension BookishExportingService: BookishExportingService.API {
  public var hasExportableRecords: Bool { !navigation.recordIDs.isEmpty }

  public func requestInterchangeExport() async {
    do {
      state.interchangeExportDocument = BookishInterchangeDocument(
        data: try await interchangeData(root: navigation.selectedRecordID))
      state.isExportingInterchange = true
    } catch {
      statusService.report(error: error)
    }
  }
}

extension BookishEngine: BookishExportingService.Access {}

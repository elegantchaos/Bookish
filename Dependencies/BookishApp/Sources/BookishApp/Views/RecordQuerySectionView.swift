// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import BookishRecordView
import Foundation
import SwiftUI

/// Resolves and displays a query-backed section embedded in a record layout.
struct RecordQuerySectionView: View {
  /// The configuration record linked by the host layout.
  let sectionID: BookishRecordID

  /// The record supplying host values for the query template.
  let host: BookishRecord

  /// The datastore coordinator used to resolve configuration and results.
  let harness: BookishHarness

  /// The command boundary used to report query-section failures.
  @Environment(\.bookishCommandCentre) private var commander

  /// The resolved section configuration record.
  @State private var section: BookishRecord?

  /// The observable result of resolving the section query against the host.
  @State private var result: RecordQueryResult?

  /// Metadata records keyed by result record kind for thumbnail placeholders.
  @State private var metadataByKind: [String: BookishRecord] = [:]

  /// The decoded template, retained for DEBUG-only diagnostics.
  @State private var template: RecordQueryTemplate?

  /// The configuration or resolution failure, retained for DEBUG-only diagnostics.
  @State private var errorDescription: String?

  /// Whether the section configuration or result is still being resolved.
  @State private var isLoading = true

  @AppStorage(.isDeveloperMode) var isDeveloperMode

  /// The section content, an optional empty message, or no content when unavailable.
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let section {
        Text(section.string(BookishRecordKey.name) ?? "Records")
          .font(.headline)

        if let result {
          if result.records.isEmpty {
            if let emptyMessage = section.string(BookishRecordKey.emptyMessage) {
              Text(emptyMessage)
                .foregroundStyle(.secondary)
            }
          } else {
            ForEach(result.records) { record in
              NavigationLink(value: record.id) {
                BookishRecordIndexCell(
                  record: record,
                  layout: nil,
                  placeholderSystemImage: metadataByKind[record.kind]?.string(BookishRecordKey.icon)
                    ?? "doc")
              }
            }
          }
        }
      } else if isLoading {
        ProgressView()
          .controlSize(.small)
      }

      if isDeveloperMode {
        queryDiagnostics
      }
    }
    .padding(.vertical, 4)
    .task(id: taskID) {
      await load()
    }
  }

  /// Identifies changes that require the section query to be resolved again.
  private var taskID: String {
    "\(sectionID.rawValue)-\(host.id.rawValue)-\(harness.revision)"
  }

  /// Resolves the section configuration and its observable host-bound query result.
  private func load() async {
    errorDescription = nil
    isLoading = true
    defer { isLoading = false }

    do {
      guard
        let section = try await harness.storageService.record(id: sectionID),
        section.kind == BookishRecordKind.querySection,
        let template = section.encoded(BookishRecordKey.query, as: RecordQueryTemplate.self)
      else {
        self.section = nil
        result = nil
        self.template = nil
        errorDescription = "The query-section configuration is missing or invalid."
        return
      }

      self.section = section
      self.template = template
      let result = try await harness.storageService.recordQueryResult(for: template, host: host)
      self.result = result
      await loadMetadata(for: result.records)
    } catch {
      result = nil
      errorDescription = error.localizedDescription
      commander?.statusReporter.report(error: error)
    }
  }

  /// Resolves the record-kind metadata used for query-result thumbnail placeholders.
  private func loadMetadata(for records: [BookishRecord]) async {
    do {
      var metadataByKind: [String: BookishRecord] = [:]

      for kind in Set(records.map(\.kind)) {
        if let metadata = try await harness.presentation.recordKindMetadata(for: kind) {
          metadataByKind[kind] = metadata
        }
      }

      self.metadataByKind = metadataByKind
    } catch {
      errorDescription = error.localizedDescription
      commander?.statusReporter.report(error: error)
    }
  }

  #if DEBUG
    /// Shows the section state and resolved query only in development builds.
    @ViewBuilder
    private var queryDiagnostics: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text("DEBUG · Query section")
          .font(.caption.weight(.semibold))
        Text("ID: \(sectionID.rawValue)")
        Text(configurationStatus)
        Text(resultStatus)
        Text(resolvedQueryDescription)
          .font(.caption.monospaced())
          .textSelection(.enabled)

        if let failure = errorDescription ?? result?.errorDescription {
          Text(failure)
            .foregroundStyle(.red)
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(8)
      .background(.quaternary, in: .rect(cornerRadius: 6))
    }

    /// Describes whether the linked configuration record could be resolved.
    private var configurationStatus: String {
      section == nil ? "Configuration: unavailable" : "Configuration: loaded"
    }

    /// Describes whether the host-bound observable result could be resolved.
    private var resultStatus: String {
      guard let result else {
        return "Result: unavailable"
      }

      return "Result: \(result.records.count) record(s)"
    }

    /// Encodes the host-bound query for diagnostics without exposing it in release builds.
    private var resolvedQueryDescription: String {
      guard let template else {
        return "No query template was decoded."
      }

      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      guard
        let data = try? encoder.encode(template.resolve(for: host)),
        let description = String(data: data, encoding: .utf8)
      else {
        return "Unable to encode the resolved query."
      }

      return description
    }
  #else
    /// Omits query diagnostics from release builds.
    private var queryDiagnostics: EmptyView {
      EmptyView()
    }
  #endif
}

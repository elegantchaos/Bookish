import BookishRecord
import SwiftUI

/// Displays a record using a simple layout record.
public struct BookishRecordView: View {
  private let presentation: BookishRecordPresentation
  private let viewerRegistry: BookishValueViewerRegistry
  private let mode: BookishValuePresentationMode

  /// Creates a record view from a data record and a layout record.
  public init(
    record: BookishRecord,
    layout: BookishRecord,
    presentationResolver: any PresentationResolver = CascadingPresentationResolver(),
    viewerRegistry: BookishValueViewerRegistry = .init(),
    mode: BookishValuePresentationMode = .viewing
  ) {
    self.init(
      record: record,
      layout: Optional(layout),
      presentationResolver: presentationResolver,
      viewerRegistry: viewerRegistry,
      mode: mode
    )
  }

  /// Creates a record view from a data record and an optional layout record.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    presentationResolver: any PresentationResolver = CascadingPresentationResolver(),
    viewerRegistry: BookishValueViewerRegistry = .init(),
    mode: BookishValuePresentationMode = .viewing
  ) {
    self.presentation = BookishRecordPresentation(
      record: record, layout: layout, presentationResolver: presentationResolver)
    self.viewerRegistry = viewerRegistry
    self.mode = mode
  }

  /// The SwiftUI content for the record detail view.
  public var body: some View {
    Form {
      if !presentation.header.isEmpty {
        Section {
          BookishRecordHeaderView(header: presentation.header)
        }
      }

      Section {
        ForEach(presentation.fields(for: mode)) { field in
          LabeledContent {
            viewerRegistry.view(for: field, mode: mode)
          } label: {
            if let icon = field.icon {
              Label(field.label, systemImage: icon)
            } else {
              Text(field.label)
            }
          }
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle(presentation.header.title ?? "")
  }
}

#Preview {
  NavigationStack {
    BookishRecordView(
      record: BookishRecord(
        id: BookishRecordID("book-preview"),
        kind: BookishRecordKind.book,
        properties: [
          BookishRecordKey.name: .string("The Left Hand of Darkness"),
          BookishRecordKey.authors: .list([.record(BookishRecordID("person-ursula-k-le-guin"))]),
          BookishRecordKey.status: .string("To Read"),
        ]
      ),
      layout: BookishRecord(
        id: BookishRecordID("layout-preview"),
        kind: BookishRecordKind.layout,
        properties: [
          BookishRecordKey.name: .string("Book"),
          BookishRecordKey.fields: .list([
            .string(BookishRecordKey.name), .string(BookishRecordKey.authors),
            .string(BookishRecordKey.status),
          ]),
        ]
      )
    )
  }
}

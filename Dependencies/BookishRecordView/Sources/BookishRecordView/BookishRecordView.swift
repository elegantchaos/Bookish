import BookishRecord
import SwiftUI

/// Displays a record using a simple layout record and optional section content.
public struct BookishRecordView<SectionContent: View>: View {
  private let presentation: BookishRecordPresentation
  private let viewerRegistry: BookishValueViewerRegistry
  private let mode: BookishValuePresentationMode
  private let sectionView: (BookishRecordID) -> SectionContent

  /// Creates a record view from a data record, optional layout, and section content.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    presentationResolver: any PresentationResolver = CascadingPresentationResolver(),
    viewerRegistry: BookishValueViewerRegistry = .init(),
    mode: BookishValuePresentationMode = .viewing,
    @ViewBuilder sectionView: @escaping (BookishRecordID) -> SectionContent
  ) {
    self.presentation = BookishRecordPresentation(
      record: record, layout: layout, presentationResolver: presentationResolver)
    self.viewerRegistry = viewerRegistry
    self.mode = mode
    self.sectionView = sectionView
  }

  /// The SwiftUI content for the record detail view.
  public var body: some View {
    Form {
      if !presentation.header.isEmpty {
        Section {
          BookishRecordHeaderView(header: presentation.header)
        }
      }

      ForEach(presentation.layoutItems(for: mode)) { item in
        if case .field(let field) = item {
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

        if case .section(let sectionID) = item {
          sectionView(sectionID)
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle(presentation.header.title ?? "")
  }
}

extension BookishRecordView where SectionContent == EmptyView {
  /// Creates a record view from a data record and layout without custom section content.
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
    ) { _ in
      EmptyView()
    }
  }

  /// Creates a record view from a data record and optional layout without custom sections.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    presentationResolver: any PresentationResolver = CascadingPresentationResolver(),
    viewerRegistry: BookishValueViewerRegistry = .init(),
    mode: BookishValuePresentationMode = .viewing
  ) {
    self.init(
      record: record,
      layout: layout,
      presentationResolver: presentationResolver,
      viewerRegistry: viewerRegistry,
      mode: mode
    ) { _ in
      EmptyView()
    }
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

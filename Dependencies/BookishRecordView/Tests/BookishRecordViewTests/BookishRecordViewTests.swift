import BookishDatastore
import BookishRecord
import SwiftUI
import Testing

@testable import BookishRecordView

struct BookishRecordViewTests {
  @Test
  func presentationUsesDefaultHeaderProperties() throws {
    let imageURL = try #require(URL(string: "https://example.com/bookish.jpg"))
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: BookishRecordKind.book,
        properties: [
          BookishRecordKey.name: .string("Bookish"),
          BookishRecordKey.subtitle: .string("A catalogue"),
          BookishRecordKey.image: .string("https://example.com/bookish.jpg"),
        ]
      ),
      layout: nil
    )

    #expect(presentation.header.title == "Bookish")
    #expect(presentation.header.subtitle == "A catalogue")
    #expect(presentation.header.thumbnailURL == imageURL)
  }

  @Test
  func presentationUsesLayoutHeaderPropertyOverrides() throws {
    let imageURL = try #require(URL(string: "https://example.com/bookish.jpg"))
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: BookishRecordKind.book,
        properties: [
          "displayTitle": .string("Bookish"),
          "tagline": .string("A catalogue"),
          "cover": .string("https://example.com/bookish.jpg"),
        ]
      ),
      layout: BookishRecord(
        kind: BookishRecordKind.layout,
        properties: [
          BookishRecordKey.titleProperty: .string("displayTitle"),
          BookishRecordKey.subtitleProperty: .string("tagline"),
          BookishRecordKey.thumbnailProperty: .string("cover"),
        ]
      )
    )

    #expect(presentation.header.title == "Bookish")
    #expect(presentation.header.subtitle == "A catalogue")
    #expect(presentation.header.thumbnailURL == imageURL)
  }

  @Test
  func presentationHeaderDoesNotFallBackToTheRecordKind() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(kind: BookishRecordKind.book),
      layout: nil
    )

    #expect(presentation.header.title == nil)
    #expect(presentation.header.subtitle == nil)
    #expect(presentation.header.thumbnailURL == nil)
  }

  @Test
  func presentationUsesLayoutFields() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "name": .string("Bookish"),
          "author": .string("Author"),
          "status": .string("Reading"),
        ]
      ),
      layout: BookishRecord(
        kind: "layout",
        properties: [
          "name": .string("Book Summary"),
          "fields": .list([.string("author"), .string("status")]),
        ]
      )
    )

    #expect(presentation.name == "Bookish")
    #expect(presentation.layoutName == "Book Summary")
    #expect(presentation.fields.map(\.key) == ["author", "status"])
    #expect(presentation.fields.map(\.value) == ["Author", "Reading"])
    #expect(presentation.fields.map(\.rawValue) == [.string("Author"), .string("Reading")])
  }

  @Test

  func viewingHidesMissingLayoutFieldsWhileEditingKeepsThemAvailable() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "name": .string("Bookish"),
          "status": .string("Reading"),
        ]
      ),
      layout: BookishRecord(
        kind: "layout",
        properties: [
          "fields": .list([.string("name"), .string("subtitle"), .string("status")])
        ]
      )
    )

    #expect(presentation.fields.map(\.key) == ["name", "status"])
    #expect(presentation.fields(for: .editing).map(\.key) == ["name", "subtitle", "status"])
    #expect(presentation.fields(for: .editing)[1].rawValue == nil)
  }

  @Test

  func alwaysShowViewerKeepsAMissingLayoutFieldVisibleWhileViewing() throws {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(kind: "book", properties: ["name": .string("Bookish")]),
      layout: BookishRecord(
        kind: "layout",
        properties: ["fields": .list([.string("name"), .string("subtitle")])]
      ),
      presentationResolver: CascadingPresentationResolver(
        presentationRecords: [
          BookishRecord(
            kind: BookishRecordKind.presentation,
            properties: [
              "subtitle": .encoded(
                try BookishEncodedValue(
                  encoding: BookishPropertyPresentation(alwaysShowViewer: true)))
            ]
          )
        ]
      )
    )

    #expect(presentation.fields.map(\.key) == ["name", "subtitle"])
    #expect(presentation.fields.last?.rawValue == nil)
  }

  @Test
  func presentationCascadesLayoutKindAndGenericPropertyMetadata() throws {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: BookishRecordKind.book,
        properties: [
          "author": .string("Author"),
          "status": .string("Reading"),
        ]
      ),
      layout: BookishRecord(
        id: BookishRecordID("layout"),
        kind: BookishRecordKind.layout,
        properties: [
          BookishRecordKey.fields: .list([.string("author"), .string("status")]),
          BookishRecordKey.presentation: .record(BookishRecordID("layout-presentation")),
        ]
      ),
      presentationResolver: CascadingPresentationResolver(
        layout: BookishRecord(
          id: BookishRecordID("layout"),
          kind: BookishRecordKind.layout,
          properties: [
            BookishRecordKey.presentation: .record(BookishRecordID("layout-presentation"))
          ]
        ),
        presentationRecords: [
          BookishRecord(
            id: BookishRecordID("kind-presentation"),
            kind: BookishRecordKind.presentation,
            properties: [
              "author": .encoded(
                try BookishEncodedValue(
                  encoding: BookishPropertyPresentation(
                    icon: "person", label: "Author", viewer: "record.link"))),
              "status": .encoded(
                try BookishEncodedValue(
                  encoding: BookishPropertyPresentation(
                    icon: "bookmark", label: "Kind Status", viewer: "status",
                    editor: "status.picker"))),
            ]
          ),
          BookishRecord(
            id: BookishRecordID("generic-presentation"),
            kind: BookishRecordKind.presentation,
            properties: [
              "author": .encoded(
                try BookishEncodedValue(
                  encoding: BookishPropertyPresentation(
                    icon: "person.fill", label: "Generic Author", editor: "text"))
              ),
              "status": .encoded(
                try BookishEncodedValue(
                  encoding: BookishPropertyPresentation(icon: "checkmark", label: "Generic Status"))
              ),
            ]
          ),
          BookishRecord(
            id: BookishRecordID("layout-presentation"),
            kind: BookishRecordKind.presentation,
            properties: [
              "status": .encoded(
                try BookishEncodedValue(
                  encoding: BookishPropertyPresentation(label: "Layout Status")))
            ]
          ),
        ],
      )
    )

    #expect(presentation.fields.map(\.label) == ["Author", "Layout Status"])
    #expect(presentation.fields.map(\.icon) == ["person", "bookmark"])
    #expect(presentation.fields.map(\.viewer) == ["record.link", "status"])
    #expect(presentation.fields.map(\.editor) == ["text", "status.picker"])
  }

  @Test
  @MainActor

  func viewerRegistryUsesMetadataBeforeNativeDefaults() throws {
    let registry = BookishValueViewerRegistry()
    let list = BookishRecordField(
      key: "authors", label: "Authors", viewer: "record.linkList", value: "Author",
      rawValue: .list([.record(BookishRecordID("author-1"))]))
    let presentation = BookishRecordField(
      key: "author", label: "Author", value: "person, Author",
      rawValue: .encoded(try BookishEncodedValue(encoding: BookishPropertyPresentation())))

    #expect(registry.identifier(for: list, mode: .viewing) == "record.linkList")
    #expect(registry.identifier(for: list, mode: .editing) == "list")
    #expect(registry.identifier(for: presentation, mode: .viewing) == "presentation")
  }

  @Test

  func presentationFallsBackToSortedRecordFieldsWithoutLayout() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "status": .string("Reading"),
          "author": .string("Author"),
        ]
      ),
      layout: nil
    )

    #expect(presentation.layoutName == "Default")
    #expect(presentation.fields.map(\.key) == ["author", "status"])
  }

  @Test

  func presentationExpandsAllOtherFieldsInLayoutOrder() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "author": .string("Author"),
          "isbn": .string("9780000000000"),
          "status": .string("Reading"),
          "name": .string("Bookish"),
        ]
      ),
      layout: BookishRecord(
        kind: "layout",
        properties: [
          "fields": .list([
            .string("name"),
            .string(BookishRecordKey.allOtherFields),
            .string("status"),
          ])
        ]
      )
    )

    #expect(presentation.fields.map(\.key) == ["name", "author", "isbn", "status"])
  }

  @Test

  func presentationAllFieldsLayoutShowsEveryRecordProperty() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "status": .string("Reading"),
          "author": .string("Author"),
        ]
      ),
      layout: BookishRecord(
        kind: "layout",
        properties: ["fields": .list([.string(BookishRecordKey.allOtherFields)])]
      )
    )

    #expect(presentation.fields.map(\.key) == ["author", "status"])
  }

  @Test
  func presentationExcludesFieldsFromAnAllFieldsLayout() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "name": .string("Bookish"),
          BookishRecordKey.originalData: .string("{\"title\":\"Bookish\"}"),
        ]
      ),
      layout: BookishRecord(
        kind: "layout",
        properties: [
          BookishRecordKey.fields: .list([.string(BookishRecordKey.allOtherFields)]),
          BookishRecordKey.excludedFields: .list([.string(BookishRecordKey.originalData)]),
        ]
      )
    )

    #expect(presentation.fields.map(\.key) == ["name"])
  }

  @Test

  func mutationPresentationDescribesSetPropertyMutation() {
    let mutation = MutationRecord(
      id: MutationID("mutation-1"),
      operation: .setProperty(
        recordID: BookishRecordID("book-1"),
        kind: "book",
        key: "reading_status",
        value: .string("Reading")
      )
    )

    let presentation = BookishMutationPresentation(mutation: mutation)

    #expect(presentation.name == "Set Reading Status")
    #expect(presentation.subtitle == "book · book-1")
    #expect(
      presentation.fields.map(\.key) == [
        "operation", "recordID", "kind", "property", "value",
      ])
    #expect(
      presentation.fields.map(\.value) == [
        "Set Property", "book-1", "book", "reading_status", "Reading",
      ])
  }

  @MainActor
  @Test

  func recordViewCanBeConstructedWithRecordAndLayout() {
    let view = BookishRecordView(
      record: BookishRecord(
        kind: "book",
        properties: [
          "name": .string("Bookish"),
          "author": .record(BookishRecordID("author-1")),
        ]),
      layout: BookishRecord(
        kind: "layout",
        properties: ["fields": .list([.string("name"), .string("author")])]
      ),
      viewerRegistry: BookishValueViewerRegistry { recordID in
        AnyView(Button(recordID.rawValue) {})
      }
    )

    _ = view.body
  }

  @MainActor
  @Test

  func recordCellCanBeConstructedWithRecordAndLayout() {
    let view = BookishRecordCell(
      record: BookishRecord(kind: "book", properties: ["name": .string("Bookish")]),
      layout: BookishRecord(kind: "layout", properties: ["fields": .list([.string("name")])])
    )

    _ = view.body
  }

  @MainActor
  @Test

  func mutationViewsCanBeConstructedWithMutation() {
    let mutation = MutationRecord(
      operation: .deleteRecord(BookishRecordID("book-1"))
    )

    let cell = BookishMutationCell(mutation: mutation)
    let detail = BookishMutationView(mutation: mutation)

    _ = cell.body
    _ = detail.body
  }
}

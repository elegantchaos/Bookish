import BookishDatastore
import BookishRecord
import SwiftUI
import Testing

@testable import BookishRecordView

struct BookishRecordViewTests {
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
        kind: BookishRecordKind.layout,
        properties: [
          BookishRecordKey.fields: .list([.string("author"), .string("status")])
        ]
      ),
      presentationResolver: CascadingPresentationResolver(presentationRecords: [
        BookishRecord(
          kind: BookishRecordKind.presentation,
          properties: [
            "status": .encoded(
              try BookishEncodedValue(
                encoding: BookishPropertyPresentation(icon: "rectangle", label: "Layout Status")))
          ]
        ),
        BookishRecord(
          kind: BookishRecordKind.presentation,
          properties: [
            "author": .encoded(
              try BookishEncodedValue(
                encoding: BookishPropertyPresentation(icon: "person", label: "Author"))),
            "status": .encoded(
              try BookishEncodedValue(
                encoding: BookishPropertyPresentation(icon: "bookmark", label: "Kind Status"))),
          ]
        ),
        BookishRecord(
          kind: BookishRecordKind.presentation,
          properties: [
            "author": .encoded(
              try BookishEncodedValue(
                encoding: BookishPropertyPresentation(icon: "person.fill", label: "Generic Author"))
            ),
            "status": .encoded(
              try BookishEncodedValue(
                encoding: BookishPropertyPresentation(icon: "checkmark", label: "Generic Status"))),
          ]
        ),
      ])
    )

    #expect(presentation.fields.map(\.label) == ["Author", "Layout Status"])
    #expect(presentation.fields.map(\.icon) == ["person", "rectangle"])
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
      customValueView: { field in
        guard let id = field.rawValue?.recordValue else {
          return nil
        }

        return AnyView(Button(id.rawValue) {})
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

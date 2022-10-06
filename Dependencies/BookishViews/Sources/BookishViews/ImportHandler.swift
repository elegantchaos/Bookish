// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCleanup
import BookishCore
import BookishImporter
import Coercion
import CoreData
import Foundation
import ThreadExtensions

class ImportHandler: ObservableObject {
    let model: ModelController
    let importController: ImportController
    let list: CDRecord
    let allImports: CDRecord
    let roleAuthor: CDRecord
    let roleIllustrator: CDRecord
    let rolePublisher: CDRecord
    let roleSeries: CDRecord
    let workContext: NSManagedObjectContext
    let seriesCleaner: SeriesCleaner
    let publisherCleaner: PublisherCleaner
    let savedUndoManager: UndoManager?

    var count = 0
    var done = 0
    var intervals: TimeInterval = 0
    var importIndex: [String:CDRecord] = [:]
    
    init(model: ModelController, importController: ImportController, context: NSManagedObjectContext, undoManager: UndoManager?) {
        self.model = model
        self.importController = importController
        self.workContext = context

        self.list = CDRecord(context: context)
        self.allImports = model.defaultList("imports", in: context)
        self.roleAuthor = model.role("author", in: context)
        self.roleIllustrator = model.role("illustrator", in: context)
        self.rolePublisher = model.role("publisher", in: context)
        self.roleSeries = model.role("series", in: context)
        self.seriesCleaner = SeriesCleaner()
        self.publisherCleaner = PublisherCleaner()
        self.savedUndoManager = undoManager
    }
    
    static func run(importer: ImportManager, source: Any, model: ModelController, importController: ImportController) {
        model.save()
        let mainContext = model.stack.viewContext
        mainContext.perform {
            let savedUndoManager = mainContext.undoManager
            mainContext.undoManager = nil

            let entities: [CDRecord] = CDRecord.everyEntity(in: mainContext)
//            for entity in entities {
//                print(entity.id)
//            }

            model.stack.onBackground { context in
                let delegate = ImportHandler(model: model, importController: importController, context: context, undoManager: savedUndoManager)
                importer.importFrom(source, delegate: delegate)
            }
        }

    }
}

extension ImportHandler: ImportDelegate {
    func session(_ session: ImportSession, willImportItems count: Int) {
        workContext.perform { [self] in
            prepare(count: count, source: session.source.localized)
        }
    }
    
    func session(_ session: ImportSession, didImport rawBook: BookRecord) {
        workContext.perform { [self] in
            process(rawBook: rawBook)
        }
    }

    func sessionDidFinish(_ session: ImportSession) {
        cleanup()
    }
    
    func sessionDidFail(_ session: ImportSession) {
        print("Import failed!") // TODO: handle error(s)
        cleanup()
    }
}

private extension ImportHandler {
    func prepare(count: Int, source: String) {

        self.count = count
        self.intervals = Date.timeIntervalSinceReferenceDate
        
        let date = Date()
        let formattedDate = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        let formattedDateTime = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .full)
        list.kind = .importSession
        list.name = "\(source) \(formattedDate)"
        list.set("Records imported from \(source) on \(formattedDateTime).", forKey: "notes")
        list.set(date, forKey: .importedDate)
        
        allImports.addToContents(list)
        
        // build an index of previously imported books
        // we will use this to attempt not to import the same book from the same source twice
        let request = CDRecord.fetchRequest(predicate: NSPredicate(format: "kindCode == \(CDRecord.Kind.book.rawValue)"))
        if let results = try? workContext.fetch(request) {
            for book in results {
                if let id = book.string(forKey: BookKey.importedID.rawValue) {
                    importIndex[id] = book
                }
            }
        }
        
        report(label: "Importing…")
    }
    
    func process(rawBook: BookRecord) {
        let importedBook = cleanupSeries(cleanupPublisher(rawBook))
        
        let book = importIndex[importedBook.id] ?? CDRecord.findOrMakeWithID(UUID().uuidString, in: workContext) { newBook in
            newBook.kind = .book
        }
        
        book.name = importedBook.title
        book.imageURL = importedBook.urls(forKey: .imageURLs).first
        book.merge(properties: importedBook.properties)
        book.set(importedBook.id, forKey: .importedID)
        book.set(importedBook.source, forKey: .source)
        list.add(book)
        done += 1

        addPeople(to: book, from: importedBook, withKey: .authors, asRole: roleAuthor)
        addPeople(to: book, from: importedBook, withKey: .illustrators, asRole: roleIllustrator)

        for publisher in importedBook.strings(forKey: .publishers) {
            let publisherRecord = CDRecord.findOrMakeWithName(publisher, kind: .publisher, in: workContext)
            book.addLink(to: publisherRecord, role: rolePublisher)
        }

        let series = importedBook.string(forKey: .series)
        if !series.isEmpty {
            let seriesRecord = CDRecord.findOrMakeWithName(series, kind: .series, in: workContext)
            book.addLink(to: seriesRecord, role: roleSeries)
        }

        report(book: importedBook)
    }
    
    func report(book: BookRecord) {
        let now = Date.timeIntervalSinceReferenceDate
        let elapsed = now - intervals
        if elapsed > 0.1 {
            intervals = now
            report(label: "Imported: \(book.title)")
            saveImportContext()
        }
    }
    
    func report(label: String) {
        let progress = ImportProgress(count: done, total: count, label: label)
        onMainQueue {
            self.importController.importProgress = progress
        }
    }
    
    func cleanup() {
        workContext.perform { [self] in
            report(label: "Finishing…")
            saveImportContext()

            let mainContext = model.stack.viewContext
            mainContext.perform { [self] in
                model.save()
                mainContext.undoManager = savedUndoManager
                importController.importProgress = nil
            }
        }
    }

    func cleanupPublisher(_ raw: BookRecord) -> BookRecord {
        let title = raw.title
        let subtitle = raw.string(forKey: .subtitle)
        let series = raw.string(forKey: .series)
        let publishers = raw.strings(forKey: .publishers)

        guard let cleaned = publisherCleaner.cleanup(book: .init(title: title, subtitle: subtitle, publishers: publishers, series: series)) else {
            return raw
        }

        var book = raw
        if book.title != cleaned.title {
            book.properties["original.title"] = book.title
            book.title = cleaned.title
        }
         
        if subtitle != cleaned.subtitle {
            if !subtitle.isEmpty {
                book.properties["original.subtitle"] = subtitle
            }
            book[.subtitle] = cleaned.subtitle.isEmpty ? nil : cleaned.subtitle
        }
        
        if series != cleaned.series {
            if !series.isEmpty {
                book.properties["original.series"] = series
            }
            book[.series] = cleaned.series.isEmpty ? nil : cleaned.series
        }

        if publishers != cleaned.publishers {
            if !publishers.isEmpty {
                book.properties["original.publisher"] = publishers
            }
            book[.publishers] = cleaned.publishers.isEmpty ? nil : cleaned.publishers
        }

        return book

    }
    
    func cleanupSeries(_ raw: BookRecord) -> BookRecord {
        let title = raw.title
        let subtitle = raw.string(forKey: .subtitle)
        let series = raw.string(forKey: .series)
        let position = raw.int(forKey: .seriesPosition)
        
        guard let cleaned = seriesCleaner.cleanup(book: .init(title: title, subtitle: subtitle, series: series, position: position)) else {
            return raw
        }
        
        var book = raw
        if book.title != cleaned.title {
            book.properties["original.title"] = book.title
            book.title = cleaned.title
        }
         
        if subtitle != cleaned.subtitle {
            if !subtitle.isEmpty {
                book.properties["original.subtitle"] = subtitle
            }
            book[.subtitle] = cleaned.subtitle.isEmpty ? nil : cleaned.subtitle
        }
        
        if series != cleaned.series {
            if !series.isEmpty {
                book.properties["original.series"] = series
            }
            book[.series] = cleaned.series.isEmpty ? nil : cleaned.series
        }
        
        if position != cleaned.position {
            if position != 0 {
                book.properties["original.position"] = position
            }
            book[.seriesPosition] = cleaned.position == 0 ? nil : cleaned.position
        }

        return book
    }
    
    func addPeople(to book: CDRecord, from importedBook: BookRecord, withKey key: BookKey, asRole role: CDRecord) {
        if let people = importedBook.properties[key] as? [String] {
            for person in people {
                let person = CDRecord.findOrMakeWithName(person, kind: .person, in: workContext)
                book.addLink(to: person, role: role)
            }
        }
    }
    
    func saveImportContext() {
        do {
            try workContext.save()
        } catch {
            print("Failed to save changes to background context")
        }
    }
}

// TODO: move into Coercion


public extension Dictionary {
    subscript(asString key: Key, default defaultValue: String, converter: Converter = StandardConverter.shared) -> String {
        return converter.asString(self[key]) ?? defaultValue
    }

    subscript(asInt key: Key, default defaultValue: Int, converter: Converter = StandardConverter.shared) -> Int {
        return converter.asInt(self[key]) ?? defaultValue
    }

    subscript(asDouble key: Key, default defaultValue: Double, converter: Converter = StandardConverter.shared) -> Double {
        return converter.asDouble(self[key]) ?? defaultValue
    }
    
    subscript(asDate key: Key, default defaultValue: Date, converter: Converter = StandardConverter.shared) -> Date {
        return converter.asDate(self[key]) ?? defaultValue
    }
}


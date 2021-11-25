// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCleanup
import BookishImporter
import CoreData
import Foundation
import ThreadExtensions

class DeliciousImportMonitor: ObservableObject {
    let model: Model
    let list: CDRecord
    let allPeople: CDRecord
    let allPublishers: CDRecord
    let allSeries: CDRecord
    let context: NSManagedObjectContext
    let seriesCleaner: SeriesCleaner
    
    var count = 0
    var done = 0
    var intervals: TimeInterval = 0
    
    init(model: Model, context: NSManagedObjectContext) {
        self.model = model
        self.context = context
        self.list = CDRecord(context: context)
        self.allPeople = context.allPeople
        self.allPublishers = context.allPublishers
        self.allSeries = context.allSeries
        self.seriesCleaner = SeriesCleaner()
        
        let date = Date()
        let formatted = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        list.name = "Delicious Library \(formatted)"
        list.set("Records imported from Delicious Library on \(formatted).", forKey: "notes")
        list.set(date, forKey: "imported")
        context.allImports.addToContents(list)
    }
}

extension DeliciousImportMonitor: ImportMonitor {
    func session(_ session: ImportSession, willImportItems count: Int) {
        self.count = count
        self.intervals = Date.timeIntervalSinceReferenceDate
        report(label: "Importing…")
    }
    
    func cleanupSeries(_ raw: DeliciousLibraryImportSession.Book) -> DeliciousLibraryImportSession.Book {
        let title = raw.title
        let subtitle = (raw.properties[.subtitleKey] as? String) ?? ""
        let series = (raw.properties[.seriesKey] as? String) ?? ""
        let position = (raw.properties[.seriesPositionKey] as? Int) ?? 0
        
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
            book.properties[.subtitleKey] = cleaned.subtitle.isEmpty ? nil : cleaned.subtitle
        }
        
        if series != cleaned.series {
            if !series.isEmpty {
                book.properties["original.series"] = series
            }
            book.properties[.seriesKey] = cleaned.series.isEmpty ? nil : cleaned.series
        }
        
        if position != cleaned.position {
            if position != 0 {
                book.properties["original.position"] = position
            }
            book.properties[.seriesPositionKey] = cleaned.position == 0 ? nil : cleaned.position
        }

        return book
    }
    
    func session(_ session: ImportSession, didImport item: Any) {
        if let rawBook = item as? DeliciousLibraryImportSession.Book {
            let importedBook = cleanupSeries(rawBook)
            
            let book: CDRecord
            if let id = UUID(uuidString: importedBook.id) { // TODO: just use the id we're given here?
                book = CDRecord.findOrMakeWithID(id.uuidString, in: context) { newBook in
                    newBook.kind = .book
                }
            } else {
                book = CDRecord.findOrMakeWithName(importedBook.title, in: context) { newBook in
                    newBook.kind = .book
                }
            }
            
            book.name = importedBook.title
            book.imageURL = importedBook.images.first
            book.merge(properties: importedBook.properties)
            list.add(book)
            done += 1

            let now = Date.timeIntervalSinceReferenceDate
            let elapsed = now - intervals
            if elapsed > 0.1 {
                intervals = now
                report(label: "Importing: \(importedBook.title)")
            }
            
            if let authors = importedBook.properties[.authorsKey] as? [String] {
                for author in authors {
                    let list = CDRecord.findOrMakeWithName(author, kind: .person, in: context)
                    allPeople.addToContents(list)
                    
                    let authorList = list.findOrMakeChildListWithName("As Author", kind: .personRole)
                    authorList.add(book)
                }
            }

            if let publishers = importedBook.properties[.publishersKey] as? [String] {
                for publisher in publishers {
                    let list = CDRecord.findOrMakeWithName(publisher, kind: .publisher, in: context)
                    self.allPublishers.addToContents(list)
                    list.add(book)
                }
            }

            if let series = importedBook.properties[.seriesKey] as? String, !series.isEmpty {
                let list = CDRecord.findOrMakeWithName(series, kind: .series, in: context)
                self.allSeries.addToContents(list)
                list.add(book)

            }
            save()
        }
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        cleanup()
    }
    
    func sessionDidFail(_ session: ImportSession) {
        print("Import failed!") // TODO: handle error(s)
        cleanup()
    }

    func report(label: String) {
        let progress = ImportProgress(count: done, total: count, label: label)
        onMainQueue {
            self.model.importProgress = progress
        }
    }
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save changes to background context")
        }
    }
    
    func cleanup() {
        report(label: "Saving…")
        save()
        onMainQueue {
            self.model.save()
            self.model.importProgress = nil
        }
    }
}

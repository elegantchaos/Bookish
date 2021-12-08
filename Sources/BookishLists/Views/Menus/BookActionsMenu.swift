// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI

struct BookActionsMenu: View {
    @EnvironmentObject var model: ModelController
    @ObservedObject var book: CDRecord
    let deleteCallback: () -> ()
    let addLinkCallback: (CDRecord.Kind) -> ()
    
    var body: some View {
        Menu("Add Link") {
            Button(action: { addLinkCallback(.person) }) { Label("Person", systemImage: "link") }
            Button(action: { addLinkCallback(.publisher) }) { Label("Publisher", systemImage: "link") }
            Button(action: { addLinkCallback(.series) }) { Label("Series", systemImage: "link") }
        }
        Button(action: deleteCallback) { Label("Delete", systemImage: "trash") }
        EditButton()
    }
}

protocol FetchProvider {
    static func request() -> NSFetchRequest<CDRecord>
}

struct PersonFetchProvider: FetchProvider {
    static func request() -> NSFetchRequest<CDRecord> {
        let request: NSFetchRequest<CDRecord> = CDRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.predicate = NSPredicate(format: "kindCode == \(CDRecord.Kind.person.rawValue)")
        return request
    }
}

struct AddLinkView<P: FetchProvider>: View {
    @EnvironmentObject var model: ModelController
    @FetchRequest(fetchRequest: P.request()) var books: FetchedResults<CDRecord>

    @State var selectedBook: String?
    @State var filter: String = ""

    init(_ provider: P.Type) {
    }
    
    var body: some View {
        VStack {
            TextField("filter", text: $filter)
            List {
                ForEach(books) { book in
                    if filter.isEmpty || book.name.contains(filter) {
                        Text(book.name)
                    }
                }
            }
        }
    }
 
}

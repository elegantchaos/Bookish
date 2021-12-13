// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI

protocol BookActionsDelegate {
    func handleDelete()
    func handlePickLink(kind: CDRecord.Kind)
    func handleAddLink(to: CDRecord)
}

struct BookActionsMenu: View {
    @EnvironmentObject var model: ModelController

    @ObservedObject var book: CDRecord
    let delegate: BookActionsDelegate
    
    var body: some View {
        Menu("Add Link") {
            AddLinkButton(kind: .person, delegate: delegate)
            AddLinkButton(kind: .publisher, delegate: delegate)
            AddLinkButton(kind: .series, delegate: delegate)
        }
        Button(action: delegate.handleDelete) { Label("Delete", systemImage: "trash") }
        EditButton()
    }
}

struct AddLinkButton: View {
    let kind: CDRecord.Kind
    let delegate: BookActionsDelegate

    var body: some View {
        Button(action: { delegate.handlePickLink(kind: kind) }) { Label(kind.roleLabel, systemImage: kind.iconName) }
    }
}

protocol FetchProvider {
    static var kind: CDRecord.Kind { get }
}

extension FetchProvider {
    static func request() -> NSFetchRequest<CDRecord> {
        let request: NSFetchRequest<CDRecord> = CDRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.predicate = NSPredicate(format: "kindCode == \(kind.rawValue)")
        return request
    }
}

class PersonFetchProvider: FetchProvider {
    static var kind: CDRecord.Kind { .person }
}

class PublisherFetchProvider: FetchProvider {
    static var kind: CDRecord.Kind { .publisher }
}

class SeriesFetchProvider: FetchProvider {
    static var kind: CDRecord.Kind { .series }
}

struct AddLinkView<P: FetchProvider>: View {
    @EnvironmentObject var model: ModelController
    @FetchRequest(fetchRequest: P.request()) var records: FetchedResults<CDRecord>

    @State var filter: String = ""

    let delegate: BookActionsDelegate

    init(_ provider: P.Type, delegate: BookActionsDelegate) {
        self.delegate = delegate
    }
    
    var body: some View {
        VStack {
            Text("Add \(P.kind.roleLabel) Link")

            TextField("filter", text: $filter)
                .padding(.horizontal)

            List {
                ForEach(records) { record in
                    if filter.isEmpty || record.name.contains(filter) {
                        Button(action: { handleAddRecord(record) }) {
                            RecordLabel(record: record)
                        }
                    }
                }
            }
            .listStyle(.plain)
//            .frame(maxHeight: .infinity)
            
            Text("End \(records.count)")
        }
        .padding(.vertical)
    }
 
    func handleAddRecord(_ record: CDRecord) {
        delegate.handleAddLink(to: record)
    }
}

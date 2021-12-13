// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

struct BookView: View {
    @Environment(\.horizontalSizeClass) var size
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var model: ModelController
    @ObservedObject var book: CDRecord
    @ObservedObject var fields: FieldList
    @State var selection: String?
    @State var isAddingLink = false
    @State var addLinkKind: CDRecord.Kind = .person

    @AppStorage("showLinks") var showLinks = true
    @AppStorage("showRaw") var  showRaw = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isAddingLink {
                AddLinkSession(kind: addLinkKind, delegate: self)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        AsyncImageView(model.image(for: book, usePlacholder: false), sizeMode: .fixedUnlessEmpty(.init(width: 256, height: 256)))
                            .padding(.bottom)
                        
                        FieldsView(record: book, fields: fields)
                            .padding(.bottom)
                        
                        DisclosureGroup("Links", isExpanded: $showLinks) {
                            VStack(alignment: .leading, spacing: 8.0) {
                                if let contained = book.containedBy?.sortedByName {
                                    ForEach(contained) { item in
                                        HStack {
                                            RecordLink(item, nameMode: .includeRole, selection: $selection)
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        DisclosureGroup("Raw Properties", isExpanded: $showRaw) {
                            LazyVStack(alignment: .leading, spacing: 8.0) {
                                let keys = book.sortedKeys
                                ForEach(keys, id: \.self) { key in
                                    if let value = book.property(forKey: key) {
                                        RawPropertyView(key: key, value: value)
                                            .padding(.bottom)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(alignment: .center) {
                    DeferredTextField(label: "Name", text: $book.name)
                    
                    if let subtitle = book.string(forKey: "subtitle") {
                        Text(subtitle)
                            .font(.subheadline)
                    }
                }
            }
            
            ToolbarItem {
                ActionsMenuButton {
                    BookActionsMenu(book: book, delegate: self)
                }
//                .popover(isPresented: $showAddLinkPopover) {
//                    addLinkPopover
//                        .frame(maxWidth: 400)
//                }
            }
        }
        .onDisappear(perform: handleDisappear)
        .onReceive(book.objectWillChange) {
            print("book changed")
            model.objectWillChange.send()
        }
    }
    
    func handleDisappear() {
        model.save()
    }
    
    @ViewBuilder var addLinkPopover: some View {
        switch addLinkKind {
            case .person:
                AddLinkView(PersonFetchProvider.self, delegate: self)

            case .series:
                AddLinkView(SeriesFetchProvider.self, delegate: self)
                
            case .publisher:
                AddLinkView(PublisherFetchProvider.self, delegate: self)
                
            default:
                EmptyView()
        }
    }
}

struct AddLinkSession: View {
    let kind: CDRecord.Kind
    let delegate: BookActionsDelegate
    var body: some View {
        switch kind {
            case .person:
                AddLinkView(PersonFetchProvider.self, delegate: delegate)

            case .series:
                AddLinkView(SeriesFetchProvider.self, delegate: delegate)
                
            case .publisher:
                AddLinkView(PublisherFetchProvider.self, delegate: delegate)
                
            default:
                EmptyView()
        }
    }
}
extension BookView: BookActionsDelegate {
    func handleDelete() {
        presentationMode.wrappedValue.dismiss()
        model.delete(book)
    }
    
    func handleAddLink(to: CDRecord) {
        isAddingLink = false
    }

    func handlePickLink(kind: CDRecord.Kind) {
        
        DispatchQueue.main.async {
            isAddingLink = true
            addLinkKind = kind
        }
    }
    
}
struct RawPropertyView: View {
    let key: String
    let value: Any
    
    var body: some View {
        let string: String
        if let list = value as? [String] {
            string = list.joined(separator: ", ")
        } else {
            string = String(describing: value)
        }
        
        return VStack(alignment: .leading) {
        if !string.isEmpty {
            Text(key)
                .foregroundColor(.secondary)
            Text(string)
        }
        }
    }
}

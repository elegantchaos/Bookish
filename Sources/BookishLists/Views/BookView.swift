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
    @State var linkSession: AddLinkSessionView.Session? = nil

    @AppStorage("showLinks") var showLinks = true
    @AppStorage("showRaw") var  showRaw = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let session = linkSession {
                AddLinkSessionView(session: session, delegate: self)
                    .toolbar {
                        ToolbarItem {
                            Button(action: { linkSession = nil} ) {
                                Text("Cancel")
                            }
                        }
                    }
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
                                        let roles = book.sortedRoles(for: item)
                                        ForEach(roles, id: \.self) { role in
                                            HStack {
                                                RecordLink(item, nameMode: .role(role), selection: .constant(nil))
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
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
                .toolbar {
                    ToolbarItem {
                        ActionsMenuButton {
                            BookActionsMenu(book: book, delegate: self)
                        }
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
}

extension BookView: BookActionsDelegate {
    func handleDelete() {
        presentationMode.wrappedValue.dismiss()
        model.delete(book)
    }
    
    func handlePickLink(kind: CDRecord.Kind, role: String) {
        DispatchQueue.main.async {
            linkSession = .init(kind: kind, role: role)
        }
    }
    
    func handleRemoveLink(to record: CDRecord, role: String) {
        if book.roles(for: record).count == 1 {
            record.removeFromContents(book)
        }
        book.removeRole(role, of: record)
    }
}

extension BookView: AddLinkDelegate {
    func handleAddLink(to linked: CDRecord) {
        if let session = linkSession {
            linked.addToContents(book)
            if let role = session.role {
                book.addRole(role, for: linked)
            }
            linkSession = nil
        }
    }
}

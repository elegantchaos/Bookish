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
    @Environment(\.editMode) var editMode
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var linkController: LinkController
    @ObservedObject var book: CDRecord
    @ObservedObject var fields: FieldList
    @State var selection: String?
    
    @AppStorage("showLinks") var showLinks = true
    @AppStorage("showRaw") var  showRaw = false
    @AppStorage("enableRawProperties") var enableRawProperties = false

    var body: some View {
        let isEditing = editMode?.wrappedValue.isEditing ?? false
        VStack(spacing: 0) {
            LinkSessionHost(delegate: self) {
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
                                                RecordLink(item, nameMode: .role(role), selection: $selection)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        if enableRawProperties {
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
                .toolbar {
                    ToolbarItem {
                        if isEditing {
                            EditButton()
                        } else {
                            ActionsMenuButton {
                                BookActionsMenu(book: book, delegate: self)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(alignment: .center) {
                    DeferredTextField(label: "Name", text: $book.name)
                        .font(.headline)
                    
                    if let subtitle = book.string(forKey: "subtitle"), !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
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
    
    func handleRemoveLink(to record: CDRecord, role: String) {
        if book.roles(for: record).count == 1 {
            record.removeFromContents(book)
        }
        book.removeRole(role, of: record)
    }
}

extension BookView: AddLinkDelegate {
    func handleAddLink(to linked: CDRecord) {
        if let session = linkController.session {
            linked.addToContents(book)
            if let role = session.role {
                book.addRole(role, for: linked)
            }
            linkController.session = nil
        }
    }
}

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
                            LazyVStack(alignment: .leading, spacing: 8.0) {
                                if let entries = book.roles() {
                                    ForEach(entries) { entry in
                                        HStack {
                                            RecordLink(entry.record, nameMode: .role(entry.role), selection: $selection)
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        RawPropertiesGroup(record: book)
                        .padding(.vertical)
                    }
                }
                .toolbar {
                    ToolbarItem {
                        if isEditing {
                            EditButton()
                        } else {
                            ActionsMenuButton {
                                BookActionsMenu()
                                    .environment(\.recordViewer, self)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(isEditing || linkController.session != nil)
        .navigationTitle(book.name)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(alignment: .center, spacing: 0.0) {
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

extension BookView: RecordViewer {
    var container: CDRecord { return book }
    func dismiss() { presentationMode.wrappedValue.dismiss() }
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

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

struct ListIndexView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var linkController: LinkController
    @Environment(\.managedObjectContext) var context
    @Environment(\.editMode) var editMode
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var list: CDRecord
    @State var selection: String?
    @State var filter: String = ""

    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        return VStack {
            LinkSessionHost(delegate: self) {
                if isEditing {
                    TextField("Notes", text: list.binding(forProperty: "notes"))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                } else {
                    Text(list.string(forKey: "notes") ?? "")
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }
                
                if isEditing {
                    FieldEditorView(fields: list.fields)
                }
                
                let items: [CDRecord] = list.sortedContents
                List(selection: $selection) {
                    ForEach(items) { item in
                        if include(item) {
                            if isEditing {
                                RecordLabel(record: item)
                            } else {
                                RecordLink(item, in: list)
                            }
                        }
                    }
                    .onDelete(perform: handleDelete)
                }
                .listStyle(.plain)
                .searchable(text: $filter)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(linkController.session != nil)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if linkController.session == nil {
                    DeferredTextField(label: "Name", text: $list.name)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("_Adding To_ \(list.name)")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if linkController.session == nil {
                    ActionsMenuButton {
                        ListActionsMenu(list: list, selection: $selection)
                            .environment(\.recordViewer, self)
                    }
                }
            }
        }
    }
    
    func include(_ item: CDRecord) -> Bool {
        filter.isEmpty || item.name.contains(filter)
    }
    
    func handleDelete(_ items: IndexSet?) {
//        if let items = items {
//            items.forEach { index in
//                let entry = list.sortedBooks[index]
//                model.delete(entry)
//            }
//            model.save()
//        }
    }
    
}

extension ListIndexView: AddLinkDelegate {
    func handleAddLink(to linked: CDRecord) {
        if let session = linkController.session {
            list.addToContents(linked)
            if let role = session.role {
                list.addLink(to: linked, role: role)
            }
            linkController.session = nil
        }
    }
}

extension ListIndexView: RecordViewer {
    var record: CDRecord { return list }
    func dismiss() { presentationMode.wrappedValue.dismiss() }
}

struct LinkSessionHost<Content>: View where Content: View {
    @EnvironmentObject var linkController: LinkController

    let delegate: AddLinkDelegate
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if let session = linkController.session {
            AddLinkSessionView(session: session, delegate: delegate)
                .onDisappear(perform: handleDisappear)
                .toolbar {
                    ToolbarItem {
                        Button(action: { linkController.session = nil} ) {
                            Text("Cancel")
                        }
                    }
                }
        } else {
            content()
        }
    }
    
    func handleDisappear() {
        if linkController.session != nil {
            print("link session was cancelled by view getting hidden")
            linkController.session = nil
        }
    }
}

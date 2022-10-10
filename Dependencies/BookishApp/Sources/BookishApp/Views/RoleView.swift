// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

/// Displays a list of the records with a given role.

struct RoleView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var linkController: LinkController
    @Environment(\.managedObjectContext) var context
    @Environment(\.editMode) var editMode
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var role: CDRecord
    let excludingKind: RecordKind
        
    @State var selection: Set<String> = []
    @State var filter: String = ""

    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        let records = sortedItems
        
        return VStack {
            LinkSessionHost(delegate: self) {
                if isEditing {
                    TextField("Notes", text: role.binding(forProperty: "notes"))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                } else {
                    Text(role.string(forKey: "notes") ?? "")
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }
                
                if isEditing {
                    FieldEditorView(fields: role.fields)
                }
                
                List(selection: $selection) {
                    ForEach(sortedItems) { item in
                        if include(item) {
                            if isEditing {
                                RecordLabel(record: item)
                            } else {
                                RecordNavigationLink(item, in: role)
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
                    DeferredTextField(label: "Name", text: $role.name)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("_Adding To_ \(role.name)")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if linkController.session == nil {
                    ActionsMenuButton {
                        RoleActionsMenu(role: role, records: records, selection: $selection)
                            .environment(\.recordViewer, self)
                    }
                }
            }
        }
    }
    
    var sortedItems: [CDRecord] {
        let links = role.linksForRole()
        let linked = links
            .compactMap { $0.contents }
            .flatMap { $0 }
            .filter { $0.kind != excludingKind }

        var deduplicated = Set(linked)
        deduplicated.remove(role)
        return deduplicated.sortedByName
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

extension RoleView: AddLinkDelegate {
    func handleAddLink(to linked: CDRecord) {
        if let session = linkController.session {
            role.addToContents(linked)
            if let role = session.role {
                role.addLink(to: linked, role: role)
            }
            linkController.session = nil
        }
    }
}

extension RoleView: RecordViewer {
    var record: CDRecord { return role }
    func dismiss() { presentationMode.wrappedValue.dismiss() }
}
